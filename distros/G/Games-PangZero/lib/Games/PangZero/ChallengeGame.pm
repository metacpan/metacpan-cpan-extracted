##########################################################################
package Games::PangZero::ChallengeGame;
##########################################################################

@ISA = qw(Games::PangZero::PlayableGameBase);
use strict;
use warnings;

sub new {
  my ($class) = @_;
  my $self = Games::PangZero::PlayableGameBase->new();
  %{$self} = (%{$self},
    'challenge' => undef,
  );
  bless $self, $class;
}

sub CreateLevelNumberSurface {
  my ($level) = @_;
  my ($surface, $w);

  $Games::PangZero::GlossyFont->use();
  $w       = Games::PangZero::Graphics::TextWidth("Level $level");
  $surface = SDL::Surface->new(SDL_SWSURFACE(), $w+6, 48, 32);
  SDLx::SFont::print_text( $surface, 3, 3, "Level $level" );

  $Games::PangZero::ScoreFont->use();
  return $surface;
}

sub SetGameLevel {
  my ($self, $level) = @_;

  Games::PangZero::SlowEffect::RemoveSlowEffects();
  $self->SUPER::SetGameLevel($level);
  $level             = $#Games::PangZero::ChallengeLevels if $level > $#Games::PangZero::ChallengeLevels;
  $self->{challenge} = $Games::PangZero::ChallengeLevels[$level];
  $self->SpawnChallenge();

  my ($levelObject, $surface);
  $levelObject            = Games::PangZero::GameObject->new();
  $surface                = CreateLevelNumberSurface($level + 1);
  $levelObject->{surface} = $surface;
  $levelObject->{w}       = $surface->w();
  $levelObject->{h}       = $surface->h();
  $levelObject->{x}       = ($Games::PangZero::ScreenWidth  - $levelObject->{w}) / 2;
  $levelObject->{y}       = ($Games::PangZero::ScreenHeight - $levelObject->{h}) / 2;
  $levelObject->{draw}    = sub { my $self = shift; SDL::Video::blit_surface($self->{surface},
                                                                             SDL::Rect->new(0, 0, $self->{surface}->w, $self->{surface}->h),
                                                                             $Games::PangZero::App, $self->{rect} ); };
  $levelObject->{advance} = sub { my $self = shift; $self->Delete() if ++$self->{time} > 200; };
  push @Games::PangZero::GameObjects, $levelObject;
}

sub AdvanceGameObjects {
  my ($self) = @_;

  if ($self->{nextlevel}) {
    Games::PangZero::PlaySound('level');
    $self->SetGameLevel($self->{level} + 1);
    delete $self->{nextlevel};
  }
  if ($self->{playerspawned}) {
    $self->SpawnChallenge();
    $self->{playerspawned} = 0;
  }
  $self->SUPER::AdvanceGameObjects();
}

sub SpawnChallenge {
  my $self = shift;
  my ($challenge, @guys, $balldesc, $ball, $hasBonus, %balls, $numBalls, $ballsSpawned, @ballKeys, $x);

  @guys = $self->PopEveryBall();
  foreach (@guys) {
    $_->{bonusDelay} = 1;
    $_->{invincible} = 1;
  }
  $Games::PangZero::GamePause = 0;
  delete $Games::PangZero::GameEvents{magic};
  $challenge = $self->{challenge};
  die unless $challenge;

  while ($challenge =~ /(\w+)/g) {
    $balldesc = $Games::PangZero::BallDesc{$1};
    warn "Unknown ball in challenge: $1" unless $balldesc;
    $balls{$1}++;
    $numBalls++;
  }
  $ballsSpawned = 0;
  while ($ballsSpawned < $numBalls) {
    foreach (keys %balls) {
      next unless $balls{$_};
      --$balls{$_};
      $balldesc = $Games::PangZero::BallDesc{$_};
      $x = $Games::PangZero::ScreenWidth * ($ballsSpawned * 2 + 1) / ($numBalls * 2) - $balldesc->{width} / 2;
      $x = $Games::PangZero::ScreenWidth - $balldesc->{width} if $x > $Games::PangZero::ScreenWidth - $balldesc->{width};
      $hasBonus = (($balldesc->{width} >= 32) and ($self->Rand(1) < $Games::PangZero::DifficultyLevel->{bonusprobability}));
      $ball = &Ball::Spawn($balldesc, $x, ($ballsSpawned % 2) ? 0 : 1, $hasBonus);
      if ($ball->{w} <= 32) {
        $ball->{ismagic} = $ball->{hasmagic} = 0;
      }
      push @Games::PangZero::GameObjects, ($ball) ;
      ++$ballsSpawned;
    }
  }
}

sub OnBallPopped {
  my $self = shift;
  my ($i);

  for ($i = $#Games::PangZero::GameObjects; $i >= 0; --$i) {
    if ($Games::PangZero::GameObjects[$i]->isa('Games::PangZero::Ball')) {
      return;
    }
  }
  $self->{nextlevel} = 1;
}

1;
