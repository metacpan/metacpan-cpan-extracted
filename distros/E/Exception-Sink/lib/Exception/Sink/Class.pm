##############################################################################
#
#  Exception::Sink::Class
#  Copyright (c) 2006-2026 Vladi Belperchinov-Shabanski "Cade"
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
use overload ( '""' => 'stringify', 'bool' => sub { 1 }, 'fallback' => 1 );
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
  my $org  = $self->{ 'ORG' };
  # like die(): text without trailing newline gets the origin appended
  return $org if $org =~ /\n$/;
  return "$org at $self->{ 'FILE' } line $self->{ 'LINE' }.\n";
}

1;
###EOF########################################################################

