##########################################################################
package Games::PangZero::PlayableGameBase;
##########################################################################

@ISA = qw( Games::PangZero::GameBase );

use strict;
use warnings;

sub new {
  my ($class) = @_;
  my $self    = Games::PangZero::GameBase->new();
  %{$self}    = (%{$self},
    'playersalive'   => 0,
    'level'          => 0,
    'backgrounds'    => [ qw( desert2.png l1.jpg  l2.jpg  l3.jpg  l4.jpg  l5.jpg  l6.jpg  l7.jpg  l8.jpg  l9.jpg )],
  );
  bless $self, $class;
}

sub ResetGame {
  my $self              = shift;
  $self->SUPER::ResetGame();
  $self->{playersalive} = 0;
  $Games::PangZero::GamePause  = 0;

  foreach my $player (@Games::PangZero::Players) {
    last if $player->{number} >= $Games::PangZero::NumGuys;
    $self->SpawnPlayer($player);
  }
  $self->SetGameLevel(0);
  $self->LayoutScoreBoard();
  push @Games::PangZero::GameObjects, (Games::PangZero::FpsIndicator->new());
}

sub SetGameSpeed {
  my $self = shift;

  $Games::PangZero::GameSpeed = 0.8 * $Games::PangZero::DifficultyLevel->{speed};
}

sub SetGameLevel {
  my ($self, $level) = @_;

  $self->{level} = $level;
  if (($level % 10) == 9) {
    $self->SetBackground( int($level / 10) + 1 );
  }
  $self->SetGameSpeed();
}

sub SpawnPlayer {
  my ($self, $player)          = @_;
  $player->{score}             = 0;
  $player->{scoreforbonuslife} = 200000;
  $player->{lives}             = 2;
  $player->{startX}            = ($Games::PangZero::ScreenWidth - $Games::PangZero::NumGuys * 60) / 2 + 60 * ($player->{number}+0.5) - 32;
  $player->{respawn}           = -1;
  my $guy                      = Games::PangZero::Guy->new($player);
  push @Games::PangZero::GameObjects, ($guy);
  ++$self->{playersalive};
  return $guy;
}

sub AdvanceGameObjects {
  my ($self) = @_;

  $self->SUPER::AdvanceGameObjects();
  $self->RespawnPlayers();
  --$Games::PangZero::GamePause if $Games::PangZero::GamePause > 0;
}

sub RespawnPlayers {
  my $self = shift;

  foreach my $player (@Games::PangZero::Players) {
    last if $player->{number} >= $Games::PangZero::NumGuys;
    if ($player->{respawn} > 0) {
      --$player->{respawn};
      $player->{score} = int($player->{respawn} / 100) if $self->{playersalive};
      if ($player->{respawn} <= 0) {
        my $guy            = $self->SpawnPlayer($player);
        $guy->{invincible} = 500;
      }
    }
  }
}

sub PlayerNextLife {
  my ($self, $guy) = @_;

  $guy->DeleteHarpoons;
  if ($guy->{player}->{lives}--) {
    $guy->{x}              = $guy->{player}->{startX};
    $guy->{y}              = $Games::PangZero::ScreenHeight - $guy->{h};
    $guy->{state}          = 'idle';
    $guy->{speedY}         = $guy->{speedX} = 0;
    $guy->{invincible}     = 500; # 0.5s
    $guy->{killed}         = 0;
    $guy->{justkilled}     = 0;
    $self->{playerspawned} = 1;
  } else {
    # One player less
    Games::PangZero::Highscore::AddHighScore($guy->{player}, $guy->{player}->{score}, $self->{level} + 1);
    $guy->Delete();
    --$self->{playersalive};
    $guy->{player}->{respawn} = 6000; # 60s
  }
}

sub PlayerDeathSequence {
  my $self = shift;
  my (@killedGuys, @deadGuys, $guy, $i);

  $self->DrawGame();
  Games::PangZero::Music::PlaySound('death');
  Games::PangZero::Graphics::RenderBorder($Games::PangZero::WhiteBorderSurface, $Games::PangZero::App);
  $Games::PangZero::App->sync();
  $self->Delay(10);
  Games::PangZero::Graphics::RenderBorder($Games::PangZero::RedBorderSurface, $Games::PangZero::App);
  Games::PangZero::Graphics::RenderBorder($Games::PangZero::RedBorderSurface, $Games::PangZero::Background);
  $Games::PangZero::App->sync();
  $self->Delay(90);

  @killedGuys = grep { $_->{justkilled}; } @Games::PangZero::GameObjects;
  foreach $guy (@killedGuys) {
    $guy->Clear();
    $guy->{killed} = 1;
    push @deadGuys, (Games::PangZero::DeadGuy->new($guy));
  }
  push @Games::PangZero::GameObjects, (@deadGuys);

  for ($i = 0; $i < 300; ++$i) {
    Games::PangZero::HandleEvents();
    return if $self->{abortgame};
    my $advance = $self->CalculateAdvances();
    while ($advance--) {
      foreach my $gameObject (@deadGuys) {
        $gameObject->Advance();
      }
    }
    $self->DrawGame();
    last if $deadGuys[0]->{deleted};
  }

  foreach $guy (@killedGuys) {
    $self->PlayerNextLife($guy);
  }

  Games::PangZero::Graphics::RenderBorder($Games::PangZero::BorderSurface, $Games::PangZero::App);
  Games::PangZero::Graphics::RenderBorder($Games::PangZero::BorderSurface, $Games::PangZero::Background);
}

sub SuperKill {
  my ($self, $guy) = @_;
  my @gameObjects  = @Games::PangZero::GameObjects;
  my $sound        = 0;
  foreach my $ball (@gameObjects) {
    next unless $ball->isa("Games::PangZero::Ball");
    $ball->Pop($guy, 'superkill');
    $sound = 1;
  }
  Games::PangZero::Music::PlaySound('pop') if $sound;
}

sub PopEveryBall {
  my $self        = shift;
  my @guys        = ();
  my @gameObjects = @Games::PangZero::GameObjects;
  foreach (@gameObjects) {
    if ($_->isa('Games::PangZero::Ball')) {
      $_->Pop(undef, 'meltdown');
    } elsif ('Games::PangZero::Guy' eq ref $_) {
      push @guys, $_;
    }
  }
  return @guys;
}

sub DeathballMeltdown {
  my ($self)           = @_;
  my ($i, $allKilled, @guys, @killedGuys, @deadGuys);
    $self->{nocollision} = 1;
  my $meltdown         = Games::PangZero::Meltdown->new();
  push @Games::PangZero::GameObjects, $meltdown;

  for ($i = 0; $i < 300; ++$i) {
    %Games::PangZero::Events = ();
    Games::PangZero::HandleEvents();
    return if $self->{abortgame};
    my $advance = $self->CalculateAdvances();
    while ($advance--) {
# TODO REINSTATE THIS IN 1.1!!!     $self->PreAdvanceAction(); # Hook for something special
      $self->SUPER::AdvanceGameObjects();
      $Games::PangZero::GamePause = 0;
      if ($meltdown->{bounce} and not $allKilled) {
        $allKilled = 1;
        @guys      = $self->PopEveryBall();
        foreach (@guys) {
          $_->{killed} = 1;
          push @deadGuys, Games::PangZero::DeadGuy->new($_);
          push @killedGuys, $_;
        }
        push @Games::PangZero::GameObjects, (@deadGuys);
      }
    }
    $self->DrawGame();
  }

  foreach (@killedGuys) {
    $self->PlayerNextLife($_);
  }

  $self->{nocollision} = 0;
}


##########################################################################
# GAME DRAWING
##########################################################################

sub DrawScoreBoard {
  my ($self) = @_;

  $self->DrawLevelIndicator( 10, $self->{scoreBoardTop} );
  for (my $i = 0; $i < $Games::PangZero::NumGuys; ++$i) {
    $self->DrawScore( $Games::PangZero::Players[$i], $Games::PangZero::Players[$i]->{scoreX}, $Games::PangZero::Players[$i]->{scoreY} );
  }
}

sub LayoutScoreBoard {
  my ($self)           = @_;
  my $scoreBoardTop    = $Games::PangZero::ScreenHeight + $Games::PangZero::ScreenMargin * 2 + 5;
  my $scoreBoardHeight = $Games::PangZero::PhysicalScreenHeight - $scoreBoardTop;
  my $rowHeight        = 64;
  my $leftMargin       = 150;
  my $rows             = $Games::PangZero::NumGuys > 4 ? 2 : 1;
  $rows                = 1 if ($scoreBoardTop + $rows * $rowHeight > $Games::PangZero::PhysicalScreenHeight);

  if ($scoreBoardTop + $rows * $rowHeight > $Games::PangZero::PhysicalScreenHeight) {
    $rowHeight     = 32;
    $scoreBoardTop = $Games::PangZero::PhysicalScreenHeight - 32;
  }

  my $guysPerRow  = int ($Games::PangZero::NumGuys / $rows + 0.5);
  my $widthPerGuy = ($Games::PangZero::PhysicalScreenWidth - $leftMargin) / $guysPerRow;

  for (my $i = 0; $i < $Games::PangZero::NumGuys; ++$i) {
    $Games::PangZero::Players[$i]->{scoreX}    = $leftMargin + ($i % $guysPerRow) * $widthPerGuy;
    $Games::PangZero::Players[$i]->{scoreY}    = $scoreBoardTop + int ($i / $guysPerRow) * $rowHeight;
    $Games::PangZero::Players[$i]->{scoreRect} =
    SDL::Rect->new($Games::PangZero::Players[$i]->{scoreX}, $Games::PangZero::Players[$i]->{scoreY},  130, $rowHeight);
  }

  $self->{scoreBoardTop}    = $scoreBoardTop;
  $self->{scoreBoardHeight} = $scoreBoardHeight;
  $self->{rowHeight}        = $rowHeight;

}

sub DrawLevelIndicator {
  my ($self, $x, $y)          = @_;
  $self->{levelIndicatorRect} = SDL::Rect->new($x, $y, 100, 32) unless $self->{levelIndicatorRect};
  SDL::Video::fill_rect($Games::PangZero::App, $self->{levelIndicatorRect}, SDL::Color->new(0, 0, 0) );
  SDLx::SFont::print_text( $Games::PangZero::App, $x, $y + 3, 'Level ' . ($self->{level}+1) );

}

sub PrintNumber {
  my ($self, $player, $x, $y, $number) = @_;
  my $numberText                       = sprintf("%d", $number);
  my $srcrect                          = SDL::Rect->new(0, 160, 16, 16);
  my $dstrect                          = SDL::Rect->new($x, $y, 16, 16);

  for (my $i = 0; $i < length($numberText); ++$i) {
    $srcrect->x(320 + (ord(substr($numberText, $i)) - ord('0')) * 16);
    $dstrect->x($x + $i * 16);
    SDL::Video::blit_surface($player->{guySurface}, $srcrect, $Games::PangZero::App, $dstrect );
  }
}

sub DrawScore {
  my ($self, $player, $x, $y, $livesY) = @_;

  #SDL::Video::fill_rect( $Games::PangZero::App, $player->{scoreRect}, SDL::Color->new(0, 0, 0));
  $self->PrintNumber( $player, $x, $y, $player->{score});

  $livesY     = $self->{rowHeight} > 32 ? $y + 24 : $y + 16;
  my $dstrect = SDL::Rect->new($x, $livesY, 32, 32);
  my $srcrect = ($self->{rowHeight} <= 32)
              ? SDL::Rect->new(320, 176, 16, 16)
              : SDL::Rect->new(320, 128, 32, 32);

  if ($player->{lives} > 3) {
    SDL::Video::blit_surface($player->{guySurface}, $srcrect, $Games::PangZero::App, $dstrect );
    $self->PrintNumber( $player, $x + $srcrect->w() + 8, $livesY + ($srcrect->h() - 16 ) / 2, $player->{lives} );
  } else {
    foreach my $i ( 0 .. $player->{lives}-1 ) {
      $dstrect->x( $x + $i * ($srcrect->w() + 4) );
      SDL::Video::blit_surface($player->{guySurface}, $srcrect, $Games::PangZero::App, $dstrect );
    }
  }
}

sub PreAdvanceAction {}

sub AdvanceGame {
  my $self                     = shift;
  %Games::PangZero::GameEvents = ();
  $self->PreAdvanceAction(); # Hook for something special

  if ($self->{superKillCount} > 0) {
    if (--$self->{superKillDelay} <= 0) {
      --$self->{superKillCount};
      $self->{superKillDelay} = 50;
      $self->SuperKill($self->{superKillGuy});
    }
    $Games::PangZero::GamePause = 0;
  }

  $self->AdvanceGameObjects();
  if ($Games::PangZero::GameEvents{earthquake}) {
    Games::PangZero::Music::PlaySound('quake');
    foreach my $guy (@Games::PangZero::GameObjects) {
      $guy->Earthquake($Games::PangZero::GameEvents{earthquake}) if ref $guy eq 'Games::PangZero::Guy';
    }
  }

  if ($Games::PangZero::GameEvents{'pop'}) {
    Games::PangZero::Music::PlaySound('pop');
  }

  if ($Games::PangZero::GameEvents{meltdown} and $Games::PangZero::DifficultyLevel->{name} ne 'Miki') {
    $self->DeathballMeltdown();
  } elsif ($Games::PangZero::GameEvents{kill} ) {
    $self->PlayerDeathSequence();
    return if $self->{playersalive} <= 0;
    $Games::PangZero::GamePause = 200 if $Games::PangZero::GamePause < 200;
    Games::PangZero::GamePause::Show();
  } elsif ($Games::PangZero::GameEvents{magic}) {
    if ($Games::PangZero::GamePause < 200) {
      $Games::PangZero::GamePause = 200;
      Games::PangZero::Music::PlaySound('pause');
      Games::PangZero::GamePause::Show();
    }
  } elsif ($Games::PangZero::GameEvents{superpause}) {
    if ($Games::PangZero::GamePause < 800) {
      $Games::PangZero::GamePause = 800;
      Games::PangZero::Music::PlaySound('pause');
      Games::PangZero::GamePause::Show();
    }
  } elsif ($Games::PangZero::GameEvents{superkill}) {
    $self->{superKillCount}  = 5;
    $self->{superKillDelay}  = 0;
    $self->{superKillGuy}    = $Games::PangZero::GameEvents{superkillguy};
    $self->{spawndelay}      = 250;
    $self->{superballdelay} += 1000; # 10 second penalty
    my @gameObjects = @Games::PangZero::GameObjects;
    foreach my $spawningBall (@gameObjects) {
      $spawningBall->Delete if $spawningBall->{spawning};
    }
  }
}

sub Run {
  my ($self) = shift;

  $self->ResetGame();
  Games::PangZero::GameTimer::ResetTimer();

  $self->{superKillCount} = 0;
  $self->{superKillDelay} = 0;
  $self->{superKillGuy}   = undef;

  while (1) {

    # Calculate advance (how many game updates to perform)
    my $advance = $self->CalculateAdvances();

    # Advance the game

    %Games::PangZero::Events = ();
    Games::PangZero::HandleEvents();
    while ($advance--) {
      return if $self->{abortgame};
      $self->AdvanceGame();
    }

    if ($self->{playersalive} <= 0) {
      my $gameoverSurface = SDL::Image::load("$Games::PangZero::DataDir/gameover.png");
      my @gameObjects     = @Games::PangZero::GameObjects;
      foreach (@gameObjects) { $_->Delete() if ('Games::PangZero::DeadGuy' eq ref $_); }
      $self->DrawGame();
      SDL::Video::blit_surface($gameoverSurface, SDL::Rect->new(0, 0, $gameoverSurface->w, $gameoverSurface->h),
                               $Games::PangZero::App, SDL::Rect->new(
                                 ($Games::PangZero::PhysicalScreenWidth - $gameoverSurface->w) / 2, $Games::PangZero::PhysicalScreenHeight / 2 - 100,
                                 $gameoverSurface->w, $gameoverSurface->h));
      $Games::PangZero::App->sync();
      SDL::delay(1000);
      for (my $i=0; $i < 20; ++$i) {
        SDL::delay(100);
        %Games::PangZero::Events = ();
        Games::PangZero::HandleEvents();
        last if $self->{abortgame};
        last if %Games::PangZero::Events;
      }
      last;
    }
    $self->DrawGame();
  }
}

1;
