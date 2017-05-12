
package My::TransmissionBeginHandler;

use strict;
use warnings 'all';
use base 'Email::Blaster::TransmissionBeginHandler';


#==============================================================================
sub run
{
  my ($s, $event) = @_;
  
  $ENV{TRANS_BEGIN_OK} = 1;
  warn $event->transmission_id . ": BEGIN";
}# end run()

1;# return true:

