package Memoize::Memcached;

use strict;
use warnings;

use Carp qw( carp croak );
use Memoize qw( unmemoize );
use Cache::Memcached;

our $VERSION = '0.04';

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;


use base 'Exporter';

our @EXPORT = qw( memoize_memcached );
our @EXPORT_OK = qw( unmemoize flush_cache );
our %EXPORT_TAGS = (
  all => [ @EXPORT, @EXPORT_OK ],
);


use fields qw(
  key_prefix
  expire_time
  memcached_obj
  key_error
  scalar_error
);



my %memo_data;
my %memcached_config;


sub memoize_memcached {
  # Be sure to leave @_ intact in case we need to redirect to
  # 'Memoize::memoize'.
  my ($function, %args) = @_;

  if (exists $args{LIST_CACHE} or exists $args{ARRAY_CACHE}) {
    carp "Call to 'memoize_memcached' with a cache option passed to 'memoize'";
    goto &Memoize::memoize;
  }

  my $memcached_args = delete $args{memcached} || {};
  croak "Invalid memcached argument (expected a hash)"
    unless ref $memcached_args eq 'HASH';

  _memcached_setup(
    %{$memcached_args},
    memoized_function => $function,
  );
  $args{LIST_CACHE} = [ HASH => $memo_data{$function}{list_cache} ];
  $args{SCALAR_CACHE} = [ HASH => $memo_data{$function}{scalar_cache} ];

  # If we are passed a normalizer, we need to keep a version of it
  # around for flush_cache to use.  This breaks encapsulation.  And it
  # is just plain ugly.
  $memo_data{$function}{normalizer} = Memoize::_make_cref($args{NORMALIZER}, scalar caller)
    if defined $args{NORMALIZER};

  # Rebuild @_ since there is a good probability we have removed some
  # arguments meant for us and added the cache arguments.
  @_ = ($function, %args);
  goto &Memoize::memoize;
}


# Unfortunately, we need to do some magic to make flush_cache sorta
# work.  I don't think this is enough magic yet.

sub flush_cache {
  # If we have exactly 1 argument then we are probably expected to
  # clear the cache for a single function.  Pass this along to
  # Memoize, even though it cannot be handled correctly at this time
  # (whatever we do will be wrong, anyway).

  goto &Memoize::flush_cache if @_ == 1;


  # If we have more than 1 argument, we are probably expected to clear
  # a single call signature for a function.  This we can almost do
  # properly.

  # Even though we can do this "properly", it is still very bad.  This
  # breaks encapsulation pretty disgustingly. With any luck Memoize
  # will eventually be patched to do this for us...

  if (@_ > 1) {
    my ($function, @args) = @_;
    my $cur_memo = $memo_data{$function};
    my $normalizer = $memo_data{$function}{normalizer};
    my $array_argstr;
    my $scalar_argstr;
    if (defined $normalizer) { 
      ($array_argstr) = $normalizer->(@_);
      $scalar_argstr = $normalizer->(@_);
    }
    else { # Default normalizer
      local $^W = 0;
      $array_argstr = $scalar_argstr = join chr(28), @args;
    }
    for my $cache (qw( list_cache scalar_cache )) {
      for my $argstr ($scalar_argstr, $array_argstr) {
        delete $cur_memo->{$cache}{$argstr};
      }
    }
    return 1;
  }


  # Currently all memoized functions share memcached config, so just
  # find the first valid object and flush cache.

  for my $function (keys %memo_data) {
    next unless $memo_data{$function}{list_obj};
    $memo_data{$function}{list_obj}{memcached_obj}->flush_all;
    last;
  }

  return 1;
}


sub import {
  my ($class) = @_;

  # Search through the arg list for the 'memcached' arg, process it,
  # and remove it (and its associated value) from the arg list in
  # anticipation of passing off to Exporter.
  for my $idx ($[ + 1 .. $#_) {
    my $arg = $_[$idx] || q();
    next unless $arg eq 'memcached';
    (undef, my $memcached_config) = splice @_, $idx, 2;
    croak "Invalid memcached config (expected a hash ref)"
      unless ref $memcached_config eq 'HASH';
    %memcached_config = %{$memcached_config};
  }

  return $class->export_to_level(1, @_);
}


sub _memcached_setup {
  my %args = %memcached_config;
  while (@_) {
    my $key = shift;
    my $value = shift;
    $args{$key} = $value;
  }

  my $function = delete $args{memoized_function};
  my $list_key_prefix = delete $args{list_key_prefix};
  my $scalar_key_prefix = delete $args{scalar_key_prefix};

  $args{key_prefix} = 'memoize-' unless defined $args{key_prefix};

  croak "Missing function name for memcached setup"
    unless defined $function;
  my $tie_data = $memo_data{$function} = {
    list_obj => undef,
    list_cache => {},
    scalar_obj => undef,
    scalar_cache => {},
  };

  my %cur_args = %args;
  $cur_args{key_prefix}
    .= (defined $function ? "$function-" : '-')
    .  (defined $list_key_prefix ? $list_key_prefix : 'list-')
    ;
  $tie_data->{list_obj} = tie %{$tie_data->{list_cache}}, __PACKAGE__, %cur_args
    or die "Error creating list cache";

  %cur_args = %args;
  $cur_args{key_prefix}
    .= (defined $function ? "$function-" : '-')
    .  (defined $scalar_key_prefix ? $scalar_key_prefix : 'scalar-')
    ;
  $tie_data->{scalar_obj} = tie %{$tie_data->{scalar_cache}}, __PACKAGE__, %cur_args
    or die "Error creating scalar cache";

  return 1;
}


sub _new {
  my $class = shift;
  croak "Called new in object context" if ref $class;
  my $self = fields::new($class);
  $self->_init(@_);
  return $self;
}


sub _init {
  my $self = shift;
  my %args = @_;
  %{$self} = ();

  $self->{key_prefix} = delete $args{key_prefix};
  $self->{key_prefix} = q() unless defined $self->{key_prefix};
  $self->{expire_time} = exists $args{expire_time} ? delete $args{expire_time} : undef;

  # Default these to false so that we can use Data::Dumper on tied
  # hashes by default.  Yes, it will show them as empty, but I doubt
  # someone running Dumper on this tied hash would really want to dump
  # the contents of the memcached cache (and they can't anyway).

  $self->{$_} = exists $args{$_} ? delete $args{$_} : !1
    for qw( key_error scalar_error );

  $self->{memcached_obj} = Cache::Memcached->new(\%args);

  return $self;
}


sub _get_key {
  my $self = shift;
  my $key = shift;
  return $self->{key_prefix} . $key;
}


sub _key_lookup_error {
  croak "Key lookup functionality is not implemented by memcached";
}


sub TIEHASH {
  my $class = shift;
  return $class->_new(@_);
}


sub STORE {
  my $self = shift;
  my $key = $self->_get_key(shift);
  my $value = shift;
  my @args = ($key, $value);
  push @args, $self->{expire_time} if defined $self->{expire_time};
  $self->{memcached_obj}->set(@args);
  return $self;
}


sub FETCH {
  my $self = shift;
  my $key = $self->_get_key(shift);
  return $self->{memcached_obj}->get($key);
}


sub EXISTS {
  my $self = shift;
  return defined $self->FETCH(@_);
}


sub DELETE {
  my $self = shift;
  my $key = $self->_get_key(shift);
  $self->{memcached_obj}->delete($key);
  return $self;
}


sub CLEAR {
  my $self = shift;
  # This is not safe because all object share memcached setup.
  $self->{memcached_obj}->flush_all;
  return $self;
}


sub FIRSTKEY {
  my $self = shift;
  return unless $self->{key_error};
  $self->_key_lookup_error;
}


sub NEXTKEY {
  my $self = shift;
  return unless $self->{key_error};
  $self->_key_lookup_error;
}


sub SCALAR {
  my $self = shift;
  return unless $self->{scalar_error};
  # I think this error still makes sense, since to determine if the
  # cache has content one would need to first determine if the cache
  # contains keys.
  $self->_key_lookup_error;
}


sub UNTIE {
  my $self = shift;
  $self->{memcached_obj}->disconnect_all;
  return $self;
}



1;

__END__

=head1 NAME

Memoize::Memcached - use a memcached cache to memoize functions


=head1 SYNOPSIS

    use Memoize::Memcached
      memcached => {
        servers => [ '127.0.0.1:11211' ],
      };

    memoize_memcached('foo');

    # Function 'foo' is now memoized using the memcached server
    # running on 127.0.0.1:11211 as the cache.


=head1 WARNING

The way C<flush_cache> works with memcached can be dangerous.  Please
read the documentation below on C<flush_cache>.


=head1 EXPORT

This module exports C<memoize_memcached>, C<flush_cache>, and
C<unmemoize>.  The C<unmemoize> function is just the one from Memoize,
and is made available for convenience.


=head1 FUNCTIONS

=head2 memoize_memcached

This is the memcached equivalent of C<memoize>.  It works very
similarly, except for some difference in options.

If the C<LIST_CACHE> or C<SCALAR_CACHE> options are passed in,
C<memoize_memcached> will complain and then pass the request along to
C<memoize>.  The result will be a memoized function, but using
whatever cache you specified and NOT using memcached at all.

This function also accepts a C<memcached> option, which expects a
hashref.  This is de-referenced and passed directly into an internal
function which sets up the memcached configuration for that function.
This contents of this hashref are mostly options passed to
C<Cache::Memcached>, with a few exceptions.

The actual key used to look up memoize data in memcached is formed
from the function name, the normalized arguments, and some additional
prefixes which can be set via the C<memcached> option.  These prefixes
are C<key_prefix>, C<list_key_prefix>, and C<scalar_key_prefix>.

The C<key_prefix> defaults to "memoize-" if it's not passed in, or an
undefined value is passed in.

The C<list_key_prefix> and C<scalar_key_prefix> options default to
"list-" and "scalar-" respectively, by the same criteria.

So, the default way the key is generated is:

  "memoize-<function>-list-<normalized args>"

or

  "memoize-<function>-scalar-<normalized args>"

The function and normalized args portion of this key are set
internally, but the "memoize-" prefix and the context portion can be
configured with memcached options as follows:

  "<key_prefix>-function-<list_key_prefix|scalar_key_prefix>-args"

Examples:

  memoize_memcached('foo');

  # keys generated will look like this:
  #  list context:   memoize-foo-list-<argument signature>
  #  scalar context: memoize-foo-scalar-<argument signature>

  memoize_memcached('foo',
    memcached => {
      servers => [ ... ],
      key_prefix        => '_M-',
      list_key_prefix   => 'L-',
      scalar_key_prefix => 'S-',
    },
    ;

  # keys generated will look like this:
  #  list context:   _M-foo-L-<argument signature>
  #  scalar context: _M-foo-S-<argument signature>

=head2 flush_cache

The behavior documented in C<Memoize> is sort of implemented.  A call
to C<flush_cache('memoized_function')> will indeed clear the cache of
all cached return values for that function, BUT it will also clear the
entire memcached cache, including all other memoized functions using
the same memcached cache, and even data unrelated to
C<Memoize::Memcached> in the same cache.  It will flush the entire
cache.

There are 2 new ways to call this function:

    flush_cache();

and

    flush_cache(memoized_function => qw( an argument signature ));

The call without arguments will flush the entire memcached cache, just
like the 1 argument version.  This includes unrelated data.  Be
careful.

The call with 2 or more arguments will flush only the cached return
values (array and scalar contexts) for a call to the function named
by the first argument with an argument signature matching the second
argument to the end.  Unlike the other 2 ways to call this function,
when called this way only the specified part of the cache is flushed.

I would recommended that only the 2 or more argument version of
C<flush_cache> be called unless you are very sure of what you are
doing.


=head1 GOTCHAS

The biggest gotcha is that you probably never want to call
C<flush_cache('memoized_function')>.  Because of the way C<CLEAR> is
implemented against memcached, this call will flush the entire
memcached cache.  Everything.  Even stuff having nothing to do with
C<Memoize::Memcached>.  You are warned.


=head1 TO-DO

A more intuitive interface for handling different memcached server
configurations would probably be useful.


=head1 AUTHOR

David Trischuk, C<< <trischuk at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-memoize-memcached at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Memoize-Memcached>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Memoize::Memcached

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Memoize-Memcached>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Memoize-Memcached>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Memoize-Memcached>

=item * Search CPAN

L<http://search.cpan.org/dist/Memoize-Memcached>

=back


=head1 ACKNOWLEDGMENTS

The tied hash portion of this module is heavily based on
C<Cache::Memcached::Tie> by Andrew Kostenko.


=head1 COPYRIGHT & LICENSE

Copyright 2008 David Trischuk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
