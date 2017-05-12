use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Support::RangeDictionary;

our $VERSION = '0.004011';

# ABSTRACT: A key -> range list mapping for support features

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );

















has 'dictionary' => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_dictionary {
  return {};
}

sub _dictionary_set {
  my ( $self, $name, $set_object ) = @_;
  $self->dictionary->{$name} = $set_object;
  return $self;
}

sub _dictionary_get {
  my ( $self, $name ) = @_;
  return unless $self->_dictionary_exists($name);
  return $self->dictionary->{$name};
}

sub _dictionary_exists {
  my ( $self, $name ) = @_;
  return exists $self->dictionary->{$name};
}

sub _dictionary_ensure_item {
  my ( $self, $name ) = @_;
  return if $self->_dictionary_exists($name);
  require Git::Wrapper::Plus::Support::RangeSet;
  $self->_dictionary_set( $name, Git::Wrapper::Plus::Support::RangeSet->new() );
  return;
}

sub _dictionary_item_add_range_object {
  my ( $self, $name, $range ) = @_;
  $self->_dictionary_ensure_item($name);
  $self->_dictionary_get($name)->add_range_object($range);
  return;
}




















sub add_range {
  my ( $self, $name, @args ) = @_;
  $self->_dictionary_ensure_item($name);
  $self->_dictionary_get($name)->add_range(@args);
  return;
}













sub has_entry {
  my ( $self, $name ) = @_;
  return $self->_dictionary_exists($name);
}











sub entries {
  my ($self)    = @_;
  my (@entries) = sort keys %{ $self->dictionary };
  return @entries;
}













sub entry_supports {
  my ( $self, $name, $version_object ) = @_;
  return unless $self->_dictionary_exists($name);
  return $self->_dictionary_get($name)->supports_version($version_object);
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support::RangeDictionary - A key -> range list mapping for support features

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

The C<RangeDictionary> associates tokens with C<RangeSet>s of C<Range>s that support that token.

    my $dict = Git::Wrapper::Plus::Support::RangeDictionary->new();
    $dict->add_range('foo' => {
        min => '1.0', max => '2.0'
    });
    $dict->add_range('bar' => {
        min => '3.0', max => '4.0'
    });
    # Returns true on Git 3.5, False on 2.5
    $dict->has_entry('bar') and $dict->entry_supports('bar', $version_object );

=head1 METHODS

=head2 C<add_range>

    $dict->add_range( name => { min => 5, max => 6 });
    $dict->add_range( name => { min => 7, max => 8 });

Is equivalent to:

    $dict->dictionary->{name} = ::RangeSet->new(
        items => [
            ::Range->new( min => 5, max => 6 ),
            ::Range->new( min => 7, max => 8 ),
        ],
    );

That is, this is a shorthand to say that for given token C<name>, that the given parameters
define an I<additional> range of versions to incorporate as being considered "supported".

=head2 C<has_entry>

Determines if a given C<name> has associated data or not.

    $dict->has_entry('name')

This method returning C<undef> should indicate that a features support status
is either unknown, or undocumented, and you should proceed with caution, assuming
either support, or non support, based on preference.

=head2 C<entries>

Returns the list of features that ranges exist for

    for my $entry ( $dict->entries ) {

    }

=head2 C<entry_supports>

Determine if a given feature supports a given version

    $dict->entry_supports( $name, $version_object );

For instance:

    $dict->entry_supports('add', $gwp->versoins );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
