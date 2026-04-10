#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

package Future::IO::Resolver::Using::LibAsyncNS 0.04;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Future::IO 0.19 qw( POLLIN );
use Future::Utils qw( repeat );

use constant HAVE_LIBASYNCNS => eval { require Net::LibAsyncNS; };

use constant RESOLVER_PRIORITY => 25;

use Future::IO::Resolver;
HAVE_LIBASYNCNS and
   Future::IO::Resolver->ADD_BACKEND( __PACKAGE__ );

use constant NS_CLASS_IN => 1;

my $asyncns;
my $runf;
my $pending_failuref;

=head1 NAME

C<Future::IO::Resolver::Using::LibAsyncNS> - implement L<Future::IO::Resolver> using F<libasyncns>

=head1 DESCRIPTION

This module provides a backend implementation for L<Future::IO::Resolver>
which uses F<libasyncns> (via the L<Net::LibAsyncNS> module) to perform its
lookups.

This should not be used directly, but is instead made available via the main
dispatch methods in C<Future::IO::Resolver> itself.

=cut

sub _asyncns ()
{
   return $asyncns if $asyncns;

   $asyncns = Net::LibAsyncNS->new( 1 );

   my $fh = $asyncns->new_handle_for_fd;

   ## This would be much neater with async/await
   $runf = Future::Utils::repeat {
      Future::IO->poll( $fh, POLLIN )->then( sub ( $ ) {
         $asyncns->wait( 0 ) or
            warn( "Future::IO::Resolver::Using::LibAsyncNS IO failure $!\n" ), return Future->done;

         while( my $q = $asyncns->getnext ) {
            my $f = $q->getuserdata;
            $f->done( $q );
         }
         Future->done;
      } )
   } while => sub ( $f ) { !$f->failure };

   $runf->on_fail( sub ( $err, @ ) {
      say "Future::IO::Resolver::Using::LibAsyncNS run future failed - $err";
      $pending_failuref = $runf;
      undef $runf;
   } );

   return $asyncns;
}

sub getaddrinfo ( $, %args )
{
   my $asyncns = _asyncns();

   if( $pending_failuref ) {
      my $f = $pending_failuref;
      undef $pending_failuref;
      return $f;
   }

   my $host    = delete $args{host};
   my $service = delete $args{service};

   my $q = $asyncns->getaddrinfo( $host, $service, \%args );

   my $f = $runf->new;
   $q->setuserdata( $f );

   my $queryf = $f->then( sub ( $q ) {
      my ( $err, @res ) = $asyncns->getaddrinfo_done( $q );

      if( !$err ) {
         Future->done( @res );
      }
      else {
         Future->fail( "$err\n", getaddrinfo => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );

   return Future->wait_any( $queryf, $runf->without_cancel );
}

sub getnameinfo ( $, %args )
{
   my $asyncns = _asyncns();

   if( $pending_failuref ) {
      my $f = $pending_failuref;
      undef $pending_failuref;
      return $f;
   }

   my $addr  = delete $args{addr};
   my $flags = delete $args{flags} // 0;

   my $q = $asyncns->getnameinfo( $addr, $flags, 1, 1 );

   my $f = $runf->new;
   $q->setuserdata( $f );

   my $queryf = $f->then( sub ( $q ) {
      my ( $err, $host, $service ) = $asyncns->getnameinfo_done( $q );

      if( !$err ) {
         Future->done( $host, $service );
      }
      else {
         Future->fail( "$err\n", getnameinfo => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );

   return Future->wait_any( $queryf, $runf->without_cancel );
}

sub res_query ( $, %args )
{
   my $asyncns = _asyncns();

   if( $pending_failuref ) {
      my $f = $pending_failuref;
      undef $pending_failuref;
      return $f;
   }

   my $dname = delete $args{dname};
   my $class = delete $args{class} // NS_CLASS_IN;
   my $type  = delete $args{type};

   my $q = $asyncns->res_query( $dname, $class, $type );

   my $f = $runf->new;
   $q->setuserdata( $f );

   my $queryf = $f->then( sub ( $q ) {
      my $answer = $asyncns->res_done( $q );

      if( defined $answer ) {
         Future->done( $answer );
      }
      else {
         Future->fail( "$!", res_query => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );

   return Future->wait_any( $queryf, $runf->without_cancel );
}

sub res_search ( $, %args )
{
   my $asyncns = _asyncns();

   if( $pending_failuref ) {
      my $f = $pending_failuref;
      undef $pending_failuref;
      return $f;
   }

   my $dname = delete $args{dname};
   my $class = delete $args{class} // NS_CLASS_IN;
   my $type  = delete $args{type};

   my $q = $asyncns->res_search( $dname, $class, $type );

   my $f = $runf->new;
   $q->setuserdata( $f );

   my $queryf = $f->then( sub ( $q ) {
      my $answer = $asyncns->res_done( $q );

      if( defined $answer ) {
         Future->done( $answer );
      }
      else {
         Future->fail( "$!", res_search => );
      }
   })->on_cancel( sub ( $ ) { $asyncns->cancel( $q ); } );

   return Future->wait_any( $queryf, $runf->without_cancel );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
