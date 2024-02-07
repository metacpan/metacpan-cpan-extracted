#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2024 -- leonerd@leonerd.org.uk

package IO::Async::Internals::FunctionWorker 0.803;

use v5.14;
use warnings;

# Called directly by IO::Async::Function::Worker when used in "code" mode,
# or by run_worker() below.
sub runloop
{
   my ( $code, $arg_channel, $ret_channel ) = @_;

   while( my $args = $arg_channel->recv ) {
      my @ret;
      my $ok = eval { @ret = $code->( @$args ); 1 };

      if( $ok ) {
         $ret_channel->send( [ r => @ret ] );
      }
      elsif( ref $@ ) {
         # Presume that $@ is an ARRAYref of error results
         $ret_channel->send( [ e => @{ $@ } ] );
      }
      else {
         chomp( my $e = "$@" );
         $ret_channel->send( [ e => $e, error => ] );
      }
   }
}

# Called by IO::Async::Function::Worker via the module+func arguments to its
# IO::Async::Routine superclass when used in "module+func" mode
sub run_worker
{
   my ( $arg_channel, $ret_channel ) = @_;

   # Setup args
   my ( $module, $func, $init_func, @init_args ) = @{ $arg_channel->recv };

   ( my $file = "$module.pm" ) =~ s{::}{/}g;
   require $file;

   my $code = $module->can( $func ) or
      die "Module $module does not provide a function called $func\n";

   if( defined $init_func ) {
      my $init = $module->can( $init_func ) or
         die "Module $module does not provide a function called $init_func\n";

      $init->( @init_args );
   }

   runloop( $code, $arg_channel, $ret_channel );
}

0x55AA;
