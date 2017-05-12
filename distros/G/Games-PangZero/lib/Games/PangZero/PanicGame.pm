##########################################################################
package Games::PangZero::PanicGame;
##########################################################################

@ISA = qw(Games::PangZero::PlayableGameBase);

sub new {
  my ($class) = @_;
  my $self    = Games::PangZero::PlayableGameBase->new();
  %{$self}    = (%{$self},
    'spawndelay'     => 0,
    'superballdelay' => 0,
    'leveladvance'   => 0,
    'panicleveldesc' => undef,
  );
  bless $self, $class;
}

sub ResetGame {
  my $self                 = shift;
  $self->SUPER::ResetGame();
  $self->{spawndelay}      = 0;
  $self->{superballdelay}  = 2500 + $self->Rand(2500);  # 25sec - 50sec
  $self->{superballdelay} *= $Games::PangZero::DifficultyLevel->{superball};
}

sub SetGameSpeed {
  my ($self) = @_;

  $Games::PangZero::GameSpeed = $self->{leveldesc}->{gamespeed} * 0.8 * $Games::PangZero::DifficultyLevel->{speed};
}

sub SetGameLevel {
  my ($self, $level) = @_;
  my ($levelIndex);

  $levelIndex = ($level > $#Games::PangZero::PanicLevels) ? $#Games::PangZero::PanicLevels : $level;
  $self->{leveldesc} = $Games::PangZero::PanicLevels[$levelIndex];
  die unless $self->{leveldesc};
  $self->{leveladvance} = 0;
  $self->SUPER::SetGameLevel($level);
}

sub AdvanceGame {
  my ($self) = @_;

  $self->SpawnBalls() if $Games::PangZero::GamePause <= 0;
  $self->SUPER::AdvanceGame();
}

sub SpawnBalls {
  my $self = shift;
  my ($randmax, $rnd, $ballName, $balldesc, $deathBallCount, $earthquakeBallCount, $hasBonus);

  --$self->{superballdelay};
  if ($self->{superballdelay} <= 0) {
    push @Games::PangZero::GameObjects, (
      Games::PangZero::Ball::Spawn($Games::PangZero::BallDesc{sprintf('super%d', $self->Rand(2))}, -1, $self->Rand(40) < 20 ? 0 : 1) );
    $self->{superballdelay} = (2500 + $self->Rand(2000)) * $Games::PangZero::DifficultyLevel->{superball}; # 25sec - 45sec
  }

  --$self->{spawndelay};
  return if $self->{spawndelay} > 0;
  $deathBallCount = $earthquakeBallCount = -1;
  $randmax = 10000;
  while ($self->{spawndelay} <= 0) {
    if ($Games::PangZero::DifficultyLevel->{name} eq 'Miki') {
      $balldesc = $Games::PangZero::BallDesc{'death'};
      last;
    }
    $rnd     = int($self->Rand($randmax));
    $randmax = 0;

    # We try to find the balldesc that falls at $rnd
    my $ballRoulette = $self->{leveldesc}->{balls};
    for (my $i = 0; $i < scalar @{$ballRoulette}; $i+=2) {
      my $rouletteWeight = $ballRoulette->[$i+1];
      $randmax          += $rouletteWeight;
      $rnd              -= $rouletteWeight;
      if ($rnd < 0) {
        $ballName = $ballRoulette->[$i];
        last;
      }
    }
    next unless ($ballName); # $rnd too large.. We'll have a better $randmax this time!

    ($balldesc) = $Games::PangZero::BallDesc{$ballName};
    if ($balldesc->{class} eq 'DeathBall') {
      next unless $Games::PangZero::DeathBallsEnabled;
      $deathBallCount = Games::PangZero::DeathBall::CountDeathBalls() if $deathBallCount < 0; # Lazy counting
      next if $deathBallCount >= 2;
    }
    if ($balldesc->{class} eq 'EarthquakeBall') {
      next unless $Games::PangZero::EarthquakeBallsEnabled;
      $earthquakeBallCount = Games::PangZero::EarthquakeBall::CountEarthquakeBalls if $earthquakeBallCount < 0;
      next if $earthquakeBallCount >= 1;
    }
    if ($balldesc->{class} eq 'WaterBall') {
      next unless $Games::PangZero::WaterBallsEnabled;
    }
    if ($balldesc->{class} eq 'SeekerBall') {
      next unless $Games::PangZero::SeekerBallsEnabled;
    }
    last if $balldesc;
  }

  $hasBonus = 1 if ($balldesc->{width} >= 32) and ($self->Rand(1) < $Games::PangZero::DifficultyLevel->{bonusprobability});

  push @Games::PangZero::GameObjects, ( Games::PangZero::Ball::Spawn($balldesc, -1, $self->Rand(40) < 20 ? 0 : 1, $hasBonus) );
  $self->{spawndelay}  = $self->{leveldesc}->{spawndelay} * $balldesc->{spawndelay} * 50;
  $self->{spawndelay} /= ($Games::PangZero::NumGuys + 1) / 2;
  $self->{spawndelay} *= $Games::PangZero::DifficultyLevel->{spawnmultiplier};
}

sub OnBallPopped {
  my $self = shift;

  ++$self->{leveladvance};
  if ($self->{leveladvance} >= 18) {
    Games::PangZero::Music::PlaySound('level');
    $self->SetGameLevel($self->{level}+1);
  }
}

sub DrawLevelIndicator {
  my ($self, $x, $y) = @_;

  $self->{levelIndicatorRect} = SDL::Rect->new($x, $y, 140, $self->{scoreBoardHeight}) unless $self->{levelIndicatorRect};
  #SDL::Video::fill_rect( $Games::PangZero::App, $self->{levelIndicatorRect}, SDL::Color->new(0,0,0) );
  SDL::Video::blit_surface($Games::PangZero::LevelIndicatorSurface2, SDL::Rect->new($x, $y, $Games::PangZero::LevelIndicatorSurface2->w, $Games::PangZero::LevelIndicatorSurface2->h),
                           $Games::PangZero::App,                    SDL::Rect->new($x, $y, 0, 0));
  SDL::Video::blit_surface($Games::PangZero::LevelIndicatorSurface, SDL::Rect->new(0, 0, 130 * $self->{leveladvance} / 17, 30), $Games::PangZero::App, SDL::Rect->new($x, $y, 0, 0));
  SDLx::SFont::print_text( $Games::PangZero::App, $x + 25, $y + 3, 'Level ' . ($self->{level}+1) );

  SDLx::SFont::print_text( $Games::PangZero::App, $x, $y + 40, sprintf('spd: %d/%d', $Games::PangZero::GameSpeed * 100, $self->{leveldesc}->{spawndelay}) ) if $self->{scoreBoardHeight} >= 64;

}

1;
