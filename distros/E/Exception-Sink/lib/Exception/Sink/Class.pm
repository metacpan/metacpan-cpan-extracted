##############################################################################
#
#  Exception::Sink::Class
#  Copyright (c) 2006-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPLv2
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

