#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2015 -- leonerd@leonerd.org.uk

package IO::Async::Resolver::DNS::LibResolvImpl;

use strict;
use warnings;

our $VERSION = '0.06';

use Net::LibResolv 0.03 qw( res_query res_search class_name2value type_name2value $h_errno );

use IO::Async::Resolver;
use constant HAVE_IO_ASYNC_RESOLVER_EXTENDED_ERROR => ( $IO::Async::Resolver::VERSION >= '0.68' );

use IO::Async::Resolver::DNS::Constants qw( /^ERR_/ );

my %errmap = (
   Net::LibResolv::HOST_NOT_FOUND => ERR_NO_HOST,
   Net::LibResolv::NO_ADDRESS     => ERR_NO_ADDRESS,
   Net::LibResolv::NO_DATA        => ERR_NO_ADDRESS,
   Net::LibResolv::NO_RECOVERY    => ERR_UNRECOVERABLE,
   Net::LibResolv::TRY_AGAIN      => ERR_TEMPORARY,
);

sub _resolve
{
   my ( $func, $dname, $class, $type ) = @_;
   my $pkt = $func->( $dname, class_name2value($class), type_name2value($type) );
   if( !defined $pkt ) {
      # We can't easily detect NODATA errors here, so we'll have to let the
      # higher-level function do it
      die HAVE_IO_ASYNC_RESOLVER_EXTENDED_ERROR
         ? [ "$h_errno", $errmap{$h_errno+0} ]
         : "$h_errno\n";
   }

   return $pkt;
}

sub IO::Async::Resolver::DNS::res_query  { _resolve( \&res_query,  @_ ) }
sub IO::Async::Resolver::DNS::res_search { _resolve( \&res_search, @_ ) }

0x55AA;
