
package Email::Blaster::MaillogWatcher;

use strict;
use warnings 'all';
use Time::HiRes 'usleep';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  $class = ref($class) ? ref($class) : $class;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub watch_maillog;

1;# return true:

