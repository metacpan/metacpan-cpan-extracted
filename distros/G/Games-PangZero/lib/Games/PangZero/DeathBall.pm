##########################################################################
package Games::PangZero::DeathBall;
##########################################################################

@ISA = qw(Games::PangZero::Ball);
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self         = Games::PangZero::Ball->new(@_);
  $self->{expires} = 2000;   # 20sec
  $self->{speedX} *= 0.9;
  bless $self, $class;
}

sub NormalAdvance {
  my $self = shift;

  $self->SUPER::NormalAdvance();
  if (--$self->{expires} < 0) {
    $self->{bonus} = 1 if $self->{hasmagic};
    $self->Pop(undef, 'expire');
  }

}

sub Pop {
  my ($self, $guy, $popEffect) = @_;
  
  $self->{dontspawn} = 1 if $popEffect eq 'expire' or $popEffect eq 'superkill';
  $self->SUPER::Pop($guy, $popEffect);
  if (CountDeathBalls() > 30) {
    $Games::PangZero::GameEvents{'meltdown'} = 1;
  }
}

sub SpawnChildren {
  my $self = shift;

  return if $self->{dontspawn};
  $self->SUPER::SpawnChildren(@_);
}

sub CountDeathBalls {
  my $count = 0;

  foreach my $ball (@Games::PangZero::GameObjects) {
    if (ref($ball) eq 'Games::PangZero::DeathBall') { ++$count; }
  }
  return $count;
}

1;
