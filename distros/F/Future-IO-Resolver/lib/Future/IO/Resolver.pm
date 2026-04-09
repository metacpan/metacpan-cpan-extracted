#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

package Future::IO::Resolver 0.03;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use meta;
no warnings 'meta::experimental';

use Carp;

# TODO: Work out how to make the LibAsyncNS one optional
our @BACKENDS = qw(
   Future::IO::Resolver::Using::LibAsyncNS
   Future::IO::Resolver::Using::Socket
);

require "${_}.pm" =~ s(::)(/)gr for @BACKENDS;

=head1 NAME

C<Future::IO::Resolver> - name resolver methods for L<Future::IO>

=head1 SYNOPSIS

=for highlighter language=perl

   use Future::IO;
   use Future::IO::Resolver;

   use Socket qw( SOCK_STREAM );

   my $f = Future::IO::Resolver->getaddrinfo(
      host     => "metacpan.org",
      service  => "http",
      socktype => SOCK_STREAM,
   );
   # when complete, $f will yield socket address structures

=head1 DESCRIPTION

This package contains a selection of methods for performing name resolver
queries, running asynchronously via L<Future::IO>. These are the sorts of
things typically performed as part of C<connect> attempts or other operations
where names have to be turned into numerical address structures, which may
involve communication with the outside world.

=head2 Implementation Details

Currently this module uses L<Net::LibAsyncNS> to offload the name resolver
operations asynchronously. This limits its abilities, and also means it relies
on having that library available. A later version of this module should expand
on this, offering possibly multiple different resolver backends for more
flexibility and portability.

=cut

=head1 METHODS

=cut

my $metapkg = meta::get_this_package;

foreach my $method (qw( getaddrinfo getnameinfo res_query res_search )) {
   $metapkg->add_named_sub( $method => sub ( $, %args ) {
      foreach my $be ( @BACKENDS ) {
         $be->can( $method ) and
            return $be->$method( %args );
      }

      croak "Cannot find a Future::IO::Resolver backend to handle ->$method";
   } );
}

=head2 getaddrinfo

   @res = await Future::IO::Resolver->getaddrinfo( %args );

Perform a C<getaddrinfo> resolve operation, which converts human-readable
descriptions of network addresses into socket-layer parameters and address
structures.

C<%args> should contain a C<host> and C<service> key, and may optionally also
specify C<family>, C<socktype>, C<protocol>, C<flags>.

The returned list will contain HASH reference structures. Each will provide
C<family>, C<socktype>, C<protocol>, C<addr> and optionally C<canonname>.

=cut

=head2 getnameinfo

   ( $host, $service ) = await Future::IO::Resolver->getnameinfo( %args );

Perform a C<getnameinfo> resolve operation, which converts socket-layer
address structures into human-readable description strings containing names
or numbers.

C<%args> should contain a C<addr> key and may optionally also specify
C<flags>.

=cut

=head2 res_query

   $answer = Future::IO::Resolver->res_query( %args );

Perform a C<res_query> resolve operation, which looks up DNS records of
various types, returning an answer in the form of a packed byte record. Code
using this method will need to understand how to unpack a DNS record from this
format.

C<%args> should contain a C<dname> and C<type> key and may optionally also
specify C<class>; though a default of the C<IN> class is applied.

=cut

=head2 res_search

   $answer = Future::IO::Resolver->res_search( %args );

Perform a C<res_search> resolve operation, which looks up DNS records of
various types, returning an answer in the form of a packed byte record. Code
using this method will need to understand how to unpack a DNS record from this
format.

C<%args> should contain a C<dname> and C<type> key and may optionally also
specify C<class>; though a default of the C<IN> class is applied.

=cut

=head1 TODO

=over 4

=item *

Some wrapping of other resolvers, like the POSIX C<get*ent> family.

=item *

Allow for optional loading of backend resolver implementations, so as not to
depend on L<Net::LibAsyncNS> all the time. Add support for direct DNS-based
resolving behaviour.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
