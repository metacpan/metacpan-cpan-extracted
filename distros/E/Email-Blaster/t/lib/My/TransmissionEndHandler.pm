
package My::TransmissionEndHandler;

use strict;
use warnings 'all';
use base 'Email::Blaster::TransmissionEndHandler';


#==============================================================================
sub run
{
  my ($s, $event) = @_;
  
  $ENV{TRANS_END_OK} = 1;
  warn $event->transmission_id . ": END";
}# end run()

1;# return true:

