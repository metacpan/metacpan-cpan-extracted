##########################################################################
package Games::PangZero::TutorialGame;
##########################################################################

@ISA = qw(Games::PangZero::ChallengeGame);
use strict;
use warnings;

sub SetChallenge {
  my ($self, $challenge) = @_;
  
  $self->{challenge} = $challenge;
}

sub SetGameLevel {
  my ($self, $level) = @_;

  $self->PlayableGameBase::SetGameLevel($level);
  $self->SpawnChallenge();
}

sub AdvanceGameObjects {
  my ($self) = @_;

  if ($self->{nextlevel}) {
    $self->{countDown} = 200;
    delete $self->{nextlevel};
  }
  if ($self->{playerspawned}) {
    $self->SpawnChallenge();
    $self->{playerspawned} = 0;
  }
  if ($self->{countDown}) {
    if (--$self->{countDown} < 1) {
      $self->{abortgame} = 1;
    }
  }
  $self->SUPER::AdvanceGameObjects();
}

1;
