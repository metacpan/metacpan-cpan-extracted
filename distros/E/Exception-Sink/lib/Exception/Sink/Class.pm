##############################################################################
#
#  Exception::Sink::Class
#  (c) Vladi Belperchinov-Shabanski "Cade" 2006-2010
#  <cade@bis.net> <cade@datamax.bg> <cade@cpan.org>
#  http://cade.datamax.bg
#
##############################################################################
#
#  sink exception class
#
##############################################################################
package Exception::Sink::Class;
use Exception::Sink;
use overload ( '""' => 'stringify' );
use strict;

##############################################################################

sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;
  my $self = { @_ };
  bless $self, $class;
  return $self;
}

sub stringify
{
  my $self = shift;
  return $self->{ 'ORG' };
}

1;
###EOF########################################################################

