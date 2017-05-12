#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package IO::Async::Resolver::StupidCache;

use strict;
use warnings;
use base qw( IO::Async::Notifier );

our $VERSION = '0.04';

use IO::Async::Resolver;

use Future 0.30; # ->without_cancel

use Struct::Dumb qw( readonly_struct );
readonly_struct CacheEntry => [qw( future expires )];

=head1 NAME

C<IO::Async::Resolver::StupidCache> - a trivial caching layer around an C<IO::Async::Resolver>

=head1 SYNOPSIS

 use IO::Async::Loop 0.62;
 use IO::Async::Resolver::StupidCache;

 my $loop = IO::Async::Loop->new;

 # Wrap the existing resolver in a cache
 $loop->set_resolver(
    IO::Async::Resolver::StupidCache->new( source => $loop->resolver )
 );

 # $loop->resolve requests will now be cached

=head1 DESCRIPTION

This object class provides a wrapper around another L<IO::Async::Resolver>
instance, which applies a simple caching layer to avoid making identical
lookups. This can be useful, for example, when performing a large number of
HTTP requests to the same host or a small set of hosts, or other cases where
it is expected that the same few resolver queries will be made over and over.

This is called a "stupid" cache because it is made without awareness of TTL
values or other cache-relevant information that may be provided by DNS or
other resolve methods. As such, it should not be relied upon to give
always-accurate answers.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item source => IO::Async::Resolver

Optional. The source of the cache data. If not supplied, a new
C<IO::Async::Resolver> instance will be constructed.

=item ttl => INT

Optional. Time-to-live of cache entries in seconds. If not supplied a default
of 5 minutes will apply.

=item max_size => INT

Optional. Maximum number of entries to keep in the cache. Entries will be
evicted at random over this limit. If not supplied a default of 1000 entries
will apply.

=back

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $params->{source} ||= IO::Async::Resolver->new;

   $params->{ttl} ||= 300;
   $params->{max_size} ||= 1000;

   $self->SUPER::_init( $params );
}

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( source ttl max_size )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 $resolver = $cache->source

Returns the source resolver

=cut

sub source
{
   my $self = shift;
   return $self->{source};
}

=head2 @result = $cache->resolve( %args )->get

=head2 @addrs = $cache->getaddrinfo( %args )->get

=head2 ( $host, $service ) = $cache->getnameinfo( %args )->get

These methods perform identically to the base C<IO::Async::Resolver> class,
except that the results are cached.

Returned C<Futures> are created with the C<without_cancel> method, so that
multiple concurrent waiters are shielded from cancellation by one another.

=cut

sub resolve
{
   my $self = shift;
   my %args = @_;

   my $type = $args{type};
   my $data = $args{data};

   my $cache = $self->{cache} ||= {};

   my $now = $self->loop->time;

   # At the current time, all the resolvers use a flat list of non-ref scalars
   # as arguments. We can simply flatten this to a string to use as our cache key

   # getaddrinfo needs special handling as it's a name/value pair list; accept
   # also getaddrinfo_hash
   my $cachekey = join "\0", ( $type =~ m/^getaddrinfo(?:_hash)?$/ )
      ? do { my %data = @$data; $type, map { $_ => $data{$_} } sort keys %data }
      : ( $type, @$data );

   if( my $entry = $cache->{$cachekey} ) {
      return $entry->future->without_cancel if $entry->expires > $now;
   }

   my $f = $self->source->resolve( %args );

   $cache->{$cachekey} = CacheEntry( $f, $now + $self->{ttl} );

   while( scalar( keys %$cache ) > $self->{max_size} ) {
      delete $cache->{ ( keys %$cache )[rand keys %$cache] };
   }

   return $f->without_cancel;
}

# Resolver's ->getaddrinfo and ->getnameinfo convenience methods are useful to
# have here, but are implemented in terms of the basic ->resolve.
# We can cheat and just import those methods directly here
*getaddrinfo = \&IO::Async::Resolver::getaddrinfo;
*getnameinfo = \&IO::Async::Resolver::getnameinfo;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
