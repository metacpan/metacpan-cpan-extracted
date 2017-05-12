package Hash::Compact;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);

our $VERSION = '0.06';

sub new {
    my $class   = shift;
    my $options = @_ > 1 && (ref $_[-1] || '') eq 'HASH' ? pop : {};
    my $self    = bless { __HASH_COMPACT_OPTIONS__ => $options }, $class;
    my $args    = shift || {};

    croak '$args must be a hash-ref'
        if (ref $args || '') ne 'HASH';

    while (my ($key, $value) = each %$args) {
        $self->param($key, $value);
    }

    $self;
}

sub options { $_[0]->{__HASH_COMPACT_OPTIONS__} }

sub keys {
    my $self = shift;
    my %alias_map;
    my @defaults;

    for my $key (CORE::keys %{$self->options}) {
        if (my $raw = $self->options->{$key}{alias_for}) {
            $alias_map{$raw} = $key;
        }
        if ($self->options->{$key}{default}) {
            push @defaults, $key;
        }
    }

    my %seen;
    grep { !$seen{$_}++ } map {
        my $key = $_;
        my $original_key = $alias_map{$key} ? $alias_map{$key} : $key;
    } grep { $_ ne '__HASH_COMPACT_OPTIONS__' } (keys %$self, @defaults);
}

sub param {
    my $self = shift;
    my $value;

    if (@_ > 1) {
        croak 'incorrect key/value pair'
            if @_ % 2;

        my %args = @_;
        while (my ($key, $value) = each %args) {
            my $option = $self->options->{$key} || {};
            $key = $option->{alias_for} || $key;

            if (defined $value && !ref $value && $value eq ($option->{default} || '')) {
                delete $self->{$key};
            }
            else {
                $self->{$key} = $value;
            }
        }
    }
    else {
        my $key    = shift;
        my $option = $self->options->{$key} || {};

        $value = $self->{$option->{alias_for} || $key} || $option->{default};
    }

    $value;
}

sub to_hash {
    warn 'to_hash() method will be deprecated at later version. use compact() instead';
    $_[0]->compact;
}

sub compact {
    my $self = shift;

    +{
        map  {
            my $value = $self->{$_};

            if (blessed $value && $value->can('to_hash')) {
                $_ => $value->compact;
            }
            else {
                $_ => $value;
            }
        } grep { $_ ne '__HASH_COMPACT_OPTIONS__' } CORE::keys %$self
    }
}

sub original {
    my $self = shift;
    +{ map { $_ => $self->param($_) } $self->keys }
}

!!1;

__END__

=encoding utf8

=head1 NAME

Hash::Compact - A hash-based object implementation with key alias and
default value support

=head1 SYNOPSIS

  package My::Memcached;

  use strict;
  use warnings;
  use parent qw(Cache::Memcached::Fast);

  use JSON;
  use Hash::Compact;

  my $OPTIONS = {
      foo => {
          alias_for => 'f',
      },
      bar => {
          alias_for => 'b',
          default   => 'bar',
      },
  };

  sub get {
      my ($self, $key) = @_;
      my $value = $self->SUPER::get($key);
      Hash::Compact->new(decode_json $value, $OPTIONS);
  }

  sub set {
      my ($self, $key, $value, $expire) = @_;
      my $hash = Hash::Compact->new($value, $OPTIONS);
      $self->SUPER::set($key, encode_json $hash->compact, $expire);
  }

  package main;

  use strict;
  use warnings;
  use Test::More;

  my $key   = 'key';
  my $value = { foo => 'foo' };
  my $memd  = My::Memcached->new({servers => [qw(localhost:11211)]});
     $memd->set($key, $value);

  my $cached_value = $memd->get($key);
  is        $cached_value->param('foo'), 'foo';
  is        $cached_value->param('bar'), 'bar';
  is_deeply $cached_value->compact, +{ f => 'foo' };

  $cached_value->param(bar => 'baz');
  $memd->set($key, $cached_value->compact);

  $cached_value = $memd->get($key);
  is        $cached_value->param('foo'), 'foo';
  is        $cached_value->param('bar'), 'baz';
  is_deeply $cached_value->compact, +{ f => 'foo', b => 'baz' };

  done_testing;

=head1 DESCRIPTION

When we store some structured value into a column of a relational
database or some key/value storage, redundancy of long key names can
be a problem for storage space.

This module is yet another hash-based object implementation which aims
to be aware of both space efficiency and easiness to use for us.

=head1 METHODS

=head2 new (I<\%hash> I<[, \%options]>)

  my $hash = Hash::Compact->new({
          foo => 'foo',
      }, {
          foo => {
              alias_for => 'f',
          },
          bar => {
              alias_for => 'b',
              default   => 'bar',
          },
      },
  );

Creates and returns a new Hash::Compact object. If C<\%options> not
passed, Hash::Compact object C<$hash> will be just a plain hash-based
object.

C<\%options> is a hash-ref which key/value pairs are associated with
ones of C<\%hash>. It may contain the fields below:

=over 4

=item * alias_for

Alias to an actual key. If it's passed, C<\%hash> will be compacted
into another hash which has aliased key. The original key of C<\%hash>
will be just an alias to an actual key.

=item * default

If this exists and the value associated with the key of C<\%hash> is
undefined, Hash::Compact object C<$hash> returns just the value. It's
for space efficiency; C<$hash> doesn't need to have key/value pair
when the value isn't defined or it's same as default value.

=back

=head2 param (I<$key>)

=head2 param (I<%pairs>)

  $hash->param('foo');          #=> 'foo'
  $hash->param('bar');          #=> 'bar' (returns the default value)

  $hash->param(
      bar => 'baz',
      qux => 'quux',
  );
  $hash->param('bar');          #=> 'baz'

Setter/getter method.

=head2 compact ()

  my $compact_hash_ref = $hash->compact;
  #=> { f => 'foo', b => 'baz' qux => 'quux' } (returns a compacted hash)

Returns a compacted hash according to C<\%options> passed into the
constructor above;

=head2 to_hash ()

This method will be deprecated and removed at later version.

=head2 keys ()

  @keys = $hash->keys; #=> (foo, bar, qux)

Returns the original key names. If C<default> option is set for a key,
the key will be returned even if the value associated with the key is
not set.

=head2 original ()

  my $original_hash_ref = $hash->original;
  #=> { foo => 'foo', bar => 'baz' qux => 'quux' } (returns an original hash)

Returns the original key-value pairs as HashRef, which includes
key-value pairs if the key-values not set but C<default> option is
designated.

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
