
package My::StartupHandler;

use strict;
use warnings 'all';
use base 'Email::Blaster::StartupHandler';


#==============================================================================
sub run
{
  my ($s, $event) = @_;
  
  $ENV{STARTUP_OK} = 1;
}# end run()

1;# return true:

