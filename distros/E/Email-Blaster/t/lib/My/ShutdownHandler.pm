
package My::ShutdownHandler;

use strict;
use warnings 'all';
use base 'Email::Blaster::ShutdownHandler';


#==============================================================================
sub run
{
  my ($s, $event) = @_;
  
  $ENV{SHUTDOWN_OK} = 1;
  warn "SHUTDOWN: $event";
}# end run()

1;# return true:

