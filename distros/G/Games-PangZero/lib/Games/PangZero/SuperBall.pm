##########################################################################
package Games::PangZero::SuperBall;
##########################################################################

@ISA = qw(Games::PangZero::Ball);
use strict;
use warnings;

sub new {
  my $class       = shift;
  my $self        = Games::PangZero::Ball->new(@_);
  $self->{effect} = 1;   # 0 : superpause;  1 : superkill
  bless $self, $class;
  $self->SwitchEffect();
  return $self;
}

sub SwitchEffect {
  my $self         = shift;
  $self->{effect}  = 1 - $self->{effect};
  $self->{surface} = $Games::PangZero::BallSurfaces{($self->{effect} ? 'gold' : 'green') . ($self->{w} > 64 ? 1 : 2)};
}

sub Bounce {
  my $self = shift;

  $self->SwitchEffect();
}

sub SpawnChildren {
  return ();
}

sub Pop {
  my $self       = shift;
  my ($poppedBy) = @_;

  $self->SUPER::Pop(@_);
  if ($self->{effect} == 0) {
    $Games::PangZero::GameEvents{superpause} = 1;
  } else {
    $Games::PangZero::GameEvents{superkill}    = 1;
    $Games::PangZero::GameEvents{superkillguy} = $poppedBy;
  }
}

sub GiveMagic {
}

1;
