
package Email::Blaster::ConfigNode;

use strict;
use warnings 'all';
use Carp 'confess';


#==============================================================================
sub new
{
  my ($class, $ref) = @_;
  local $SIG{__DIE__} = \&Carp::confess;
  my $s = bless $ref, $class;
  $s->init_keys();
  $s;
}# end new()


#==============================================================================
sub init_keys
{
  my $s = shift;
  
  foreach my $key ( grep { ref($s->{$_}) eq 'HASH' } keys(%$s) )
  {
    if( $key eq 'throttled' )
    {
      require Email::Blaster::ConfigNode::Throttled;
      $s->{$key} = Email::Blaster::ConfigNode::Throttled->new( delete($s->{$key}) );
    }
    elsif( $key eq 'cluster' )
    {
      require Email::Blaster::ConfigNode::Cluster;
      $s->{$key} = Email::Blaster::ConfigNode::Cluster->new( delete($s->{$key}) );
    }
    else
    {
      $s->{$key} = __PACKAGE__->new( $s->{$key} );
    }# end if()
  }# end foreach()
}# end init_keys()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  confess "Unknown method or property '$name'" unless exists($s->{$name});
  
  # Setter/Getter:
  @_ ? $s->{$name} = shift : $s->{$name};
}# end AUTOLOAD()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:


