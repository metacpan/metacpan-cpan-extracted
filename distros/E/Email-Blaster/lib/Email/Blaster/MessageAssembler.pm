
package Email::Blaster::MessageAssembler;

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
sub assemble
{
  my ($s, $blaster, $sendlog, $transmission) = @_;
  
  return {
    subject => $transmission->subject,
    content => $transmission->content,
  };
}# end assemble()

1;# return true:

