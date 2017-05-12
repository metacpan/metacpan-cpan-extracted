##########################################################################
package Games::PangZero::UpsideDownBall;
##########################################################################

@ISA = qw( Games::PangZero::Ball );
use strict;
use warnings;

sub NormalAdvance {
  my ($self) = @_;
  
  $self->{speedY} = -$self->{speedY};
  $self->{y}      = $Games::PangZero::ScreenHeight - $self->{h} - $self->{y};
  $self->SUPER::NormalAdvance();
  $self->{speedY} = -$self->{speedY};
  $self->{y}      = $Games::PangZero::ScreenHeight - $self->{h} - $self->{y};
}

1;
