#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2013 -- leonerd@leonerd.org.uk

package IO::Async::Resolver::DNS::NetDNSImpl;

use strict;
use warnings;

our $VERSION = '0.06';

use Net::DNS::Resolver;

use IO::Async::Resolver;
use constant HAVE_IO_ASYNC_RESOLVER_EXTENDED_ERROR => ( $IO::Async::Resolver::VERSION >= '0.68' );

use IO::Async::Resolver::DNS::Constants qw( /^ERR_/ );

# Net::DNS::Resolver sometimes just sets its error strings to the stringified version of $!
use constant EAGAIN_STR => do { $! = Errno::EAGAIN; "$!" };

my $res;
sub _resolve
{
   my ( $method, $dname, $class, $type ) = @_;

   $res ||= Net::DNS::Resolver->new;

   my $pkt = $res->$method( $dname, $type, $class ); # !order
   if( !$pkt ) {
      my $errorstring = $res->errorstring;
      # Net::DNS::Resolver yields NOERROR for successful DNS queries that just
      # didn't yield any records of the type we wanted. Rewrite that into
      # NODATA instead
      $errorstring = "NODATA" if $errorstring eq "NOERROR";

      if( HAVE_IO_ASYNC_RESOLVER_EXTENDED_ERROR ) {
         # Attempt to convert Net::DNS::Resolver's error strings to our own
         # constants
         my $err = ERR_UNRECOVERABLE;
         for( $errorstring ) {
            # RCODE errors in the DNS packet response
            m/^NODATA$/      and $err = ERR_NO_ADDRESS, last;
            m/^NXDOMAIN$/    and $err = ERR_NO_HOST,    last;
            m/^SRVFAIL$/     and $err = ERR_TEMPORARY,  last;
            # libc errno values which arrive as strings :(
            $_ eq EAGAIN_STR and $err = ERR_TEMPORARY,  last;
            # It is quite likely this mapping is incomplete. :(
         }

         die [ "$errorstring", $err ];
      }
      else {
         die "$errorstring\n";
      }
   }

   # placate Net::DNS::Packet bug
   $pkt->answer; $pkt->authority; $pkt->additional;

   return $pkt->data;
}

sub IO::Async::Resolver::DNS::res_query  { _resolve( query  => @_ ) }
sub IO::Async::Resolver::DNS::res_search { _resolve( search => @_ ) }

0x55AA;
