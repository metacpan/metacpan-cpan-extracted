##########################################################################
package Games::PangZero::DemoGame;
##########################################################################

@ISA = qw(Games::PangZero::PanicGame);

sub ResetGame {
  my $self = shift;
  Games::PangZero::Config::SetDifficultyLevel(1);
  Games::PangZero::Config::SetWeaponDuration(0);
  $Games::PangZero::Slippery = 0;
  $self->SUPER::ResetGame();

  my $ball = Games::PangZero::Ball::Create($Games::PangZero::BallDesc[4], 400, 0, -10, 0);
  $ball->GiveMagic();

  push @Games::PangZero::GameObjects, (
    Games::PangZero::Ball::Create($Games::PangZero::BallDesc[0], 100, 0, 1),
    Games::PangZero::Ball::Create($Games::PangZero::BallDesc{super0}, 300, 0, 0),
    Games::PangZero::Ball::Create($Games::PangZero::BallDesc{super1}, 500, 0, 1),
    $ball,
  );
  $Games::PangZero::GamePause = 0;
  $Games::PangZero::GameSpeed = 0.8;
  $self->{spawndelay}  = $self->{superballdelay} = 1000000;
  $self->{ballcounter} = 0;
  $self->{balls}       =  [ qw(b0 h0 w1 quake death seeker) ];
}

sub SetGameSpeed {
  $Games::PangZero::GameSpeed = 0.8;
}

sub SpawnBalls {
  my $self = shift;
  
  return if (--$self->{spawndelay} > 0);
  my $ballName = $self->{balls}->[$self->{ballcounter}];
  return unless $ballName;
  push @Games::PangZero::GameObjects, ( Games::PangZero::Ball::Spawn($Games::PangZero::BallDesc{$ballName}, 100, 1, 0) );
  $self->{spawndelay} = 1000000;
  ++$self->{ballcounter};
}

sub RespawnPlayers {}
sub OnBallPopped {}

1;
