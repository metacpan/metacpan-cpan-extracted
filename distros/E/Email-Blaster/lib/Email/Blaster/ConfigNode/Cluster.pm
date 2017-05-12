
package Email::Blaster::ConfigNode::Cluster;

use strict;
use warnings 'all';
use base 'Email::Blaster::ConfigNode';


#==============================================================================
sub new
{
  my ($class, $ref) = @_;
  
  my $s = $class->SUPER::new( $ref );
  
  $s->{servers} ||= { server => [ ] };
  $s->{servers}->{server} ||= [ ];
  $s->{servers} = $class->SUPER::new( delete( $s->{servers} ) );
  
  return $s;
}# end new()


#==============================================================================
sub servers
{
  my $s = shift;
  
  @{ $s->{servers}->server };
}# end throttled()

1;# return true:

