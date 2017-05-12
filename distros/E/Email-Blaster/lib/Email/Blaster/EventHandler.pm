
package Email::Blaster::EventHandler;

use strict;
use warnings 'all';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  $class = ref($class) ? ref($class) : $class;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub run
{
  my ($s, $event) = @_;
}# end run()

1;# return true:

