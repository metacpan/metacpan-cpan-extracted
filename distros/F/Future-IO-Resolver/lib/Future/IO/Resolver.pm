#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

package Future::IO::Resolver 0.01;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Future::IO qw( POLLIN );
use Future::Utils qw( repeat );

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

# TODO: This is all heavily specific to libasyncns right now.
require Net::LibAsyncNS;

use constant NS_CLASS_IN => 1;

my $asyncns;
my $runf;

sub _asyncns ()
{
   return $asyncns if $asyncns;

   $asyncns = Net::LibAsyncNS->new( 1 );

   my $fh = $asyncns->new_handle_for_fd;

   ## This would be much neater with async/await
   $runf = Future::Utils::repeat {
      Future::IO->poll( $fh, POLLIN )->then( sub ( $ ) {
         $asyncns->wait( 0 ) or
            warn( "Future::IO::Resolver IO failure $!\n" ), return Future->done;

         while( my $q = $asyncns->getnext ) {
            my $f = $q->getuserdata;
            $f->done( $q );
         }
         Future->done;
      } );
   } while => sub ( $ ) { 1 };

   $runf->on_fail( sub ( $err, @ ) {
      say "Future::IO::Resolver run future failed - $err";
   } );

   return $asyncns;
}

=head1 METHODS

=cut

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

sub getaddrinfo ( $, %args )
{
   my $asyncns = _asyncns();

   my $host    = delete $args{host};
   my $service = delete $args{service};

   my $q = $asyncns->getaddrinfo( $host, $service, \%args );

   my $f = $runf->new;
   $q->setuserdata( $f );

   return $f->then( sub ( $q ) {
      my ( $err, @res ) = $asyncns->getaddrinfo_done( $q );

      if( !$err ) {
         Future->done( @res );
      }
      else {
         Future->fail( "$err\n", getaddrinfo => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );
}

=head2 getnameinfo

   ( $host, $service ) = await Future::IO::Resolver->getnameinfo( %args );

Perform a C<getnameinfo> resolve operation, which converts socket-layer
address structures into human-readable description strings containing names
or numbers.

C<%args> should contain a C<addr> key and may optionally also specify
C<flags>.

=cut

sub getnameinfo ( $, %args )
{
   my $asyncns = _asyncns();

   my $addr  = delete $args{addr};
   my $flags = delete $args{flags} // 0;

   my $q = $asyncns->getnameinfo( $addr, $flags, 1, 1 );

   my $f = $runf->new;
   $q->setuserdata( $f );

   return $f->then( sub ( $q ) {
      my ( $err, $host, $service ) = $asyncns->getnameinfo_done( $q );

      if( !$err ) {
         Future->done( $host, $service );
      }
      else {
         Future->fail( "$err\n", getnameinfo => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );
}

=head2 res_query

   $answer = Future::IO::Resolver->res_query( %args );

Perform a C<res_query> resolve operation, which looks up DNS records of
various types, returning an answer in the form of a packed byte record. Code
using this method will need to understand how to unpack a DNS record from this
format.

C<%args> should contain a C<dname> and C<type> key and may optionally also
specify C<class>; though a default of the C<IN> class is applied.

=cut

sub res_query ( $, %args )
{
   my $asyncns = _asyncns();

   my $dname = delete $args{dname};
   my $class = delete $args{class} // NS_CLASS_IN;
   my $type  = delete $args{type};

   my $q = $asyncns->res_query( $dname, $class, $type );

   my $f = $runf->new;
   $q->setuserdata( $f );

   return $f->then( sub ( $q ) {
      my $answer = $asyncns->res_done( $q );

      if( defined $answer ) {
         Future->done( $answer );
      }
      else {
         Future->fail( "$!", res_query => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );
}

=head2 res_search

   $answer = Future::IO::Resolver->res_search( %args );

Perform a C<res_search> resolve operation, which looks up DNS records of
various types, returning an answer in the form of a packed byte record. Code
using this method will need to understand how to unpack a DNS record from this
format.

C<%args> should contain a C<dname> and C<type> key and may optionally also
specify C<class>; though a default of the C<IN> class is applied.

=cut

sub res_search ( $, %args )
{
   my $asyncns = _asyncns();

   my $dname = delete $args{dname};
   my $class = delete $args{class} // NS_CLASS_IN;
   my $type  = delete $args{type};

   my $q = $asyncns->res_search( $dname, $class, $type );

   my $f = $runf->new;
   $q->setuserdata( $f );

   return $f->then( sub ( $q ) {
      my $answer = $asyncns->res_done( $q );

      if( defined $answer ) {
         Future->done( $answer );
      }
      else {
         Future->fail( "$!", res_search => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );
}

=head1 TODO

=over 4

=item *

Proper error handling if the run future dies; clear state and fail all pending
queries.

=item *

Some wrapping of other resolvers, like the POSIX C<get*ent> family.

=item *

Look into other backends - will be necessary for other resolver types too.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
