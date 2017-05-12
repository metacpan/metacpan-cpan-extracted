##########################################################################
package Games::PangZero::Guy;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);
use vars qw(%Guys $GuyId);

sub new {
  my ($class, $player) = @_;
  my $self             = Games::PangZero::GameObject->new();
  my $number           = $player->{number};
  %{$self}             = ( %{$self},
    'player' => $player,
    'number' => $number,
    'x' => $player->{startX},
    'y' => $Games::PangZero::ScreenHeight - 64,
    'w' => 64,
    'h' => 64,
    'collisionw' => '28',
    'collisionh' => '48',
    'delay' => 0,
    'speedY' => 0,
    'speedX' => 0,
    'dir' => $number % 2,
    'state' => 'idle',
    'killed' => 0,
    'harpoons' => 0,
    'invincible' => 0,
    'surface' => $player->{guySurface},
    'whiteSurface' => $player->{whiteGuySurface},
    'weapon' => 'Harpoon',
    'bonusDelay' => 0,
    'id' => ++$GuyId,
  );
  bless $self, $class;
  $self->SetupCollisions();
  $self->CalculateAnimPhases();
  $Guys{$self->{id}} = $self;
  return $self;
}

sub Delete {
  my $self = shift;

  $self->SUPER::Delete;
  delete $Guys{$self->{id}};
}

sub CalculateAnimPhases {
  my $self = shift;

  $self->{animPhases} = $self->{player}->{guySurface}->w / 128,
}

sub DemoMode {
  my ($self)     = shift;
  $self->{state} = 'demo';
  $self->{dir}   = 1;
}

sub Fire {
  my ($self) = @_;

  if ($self->{harpoons} < $Games::PangZero::DifficultyLevel->{harpoons}) {
    ++$self->{harpoons};
    eval("unshift \@Games::PangZero::GameObjects, (Games::PangZero::$self->{weapon}::Create(\$self));");
    $self->{state} = 'shoot';
    $self->{delay} = 7;
    Games::PangZero::Music::PlaySound('shoot');
    return 1;
  }
  return 0;
}

sub AdvanceWhileFlying {
  my $self = shift;

  $self->{speedY} += $Games::PangZero::Ball::Gravity * 2;
  $self->{y}      += $self->{speedY};
  $self->{x}      += $self->{dir} > 0 ? 1 : -1;
  if ($self->{x} < -16) {
    $self->{x} = 0;
    $self->{dir} = 1;
  }
  if ($self->{x} > $Games::PangZero::ScreenWidth - $self->{w} + 16) {
    $self->{x} = $Games::PangZero::ScreenWidth - $self->{w}; $self->{dir} = 0;
  }
  if ($self->{y} >= $Games::PangZero::ScreenHeight - $self->{h}) {
    $self->{state}  = 'idle';
    $self->{y}      = $Games::PangZero::ScreenHeight - $self->{h};
    $self->{speedX} = $self->{dir} ? 1 : -1;
  }
}

sub Advance {
  my ($self) = @_;
  my ($slippery, $keys);

  $slippery = $Games::PangZero::Slippery ? 0.0625 : 0;

  return if $self->{killed};
  return if $self->{state} eq 'demo';
  --$self->{invincible};

  if ($self->{bonusDelay} > 0) {
    --$self->{bonusDelay};
    $self->{weapon} = 'Harpoon' if $self->{bonusDelay} <= 0;
  }

  if ($self->{state} eq 'fly') {
    $self->AdvanceWhileFlying();
    return;
  }

  if ($self->{delay} > 0) {
    --$self->{delay};
    $keys = [ 0, 0, 0 ];
  } else {
    $keys = $self->{player}->{keys};
  }

  $self->{speedX} = 0 unless $slippery;
  $self->{state} = 'idle';

  if ( $Games::PangZero::Events{$keys->[2]} ) {
    return if $self->Fire();
  }
  if ( $Games::PangZero::Keys{$keys->[0]} ) {
    if ($slippery) {
      $self->{speedX} -= $slippery * 2 if $self->{speedX} > -3;
    } else {
      $self->{speedX} = -3;
    }
    $self->{dir} = 0;
    $self->{state} = 'walk';
  } elsif ( $Games::PangZero::Keys{$keys->[1]} ) {
    if ($slippery) {
      $self->{speedX} += $slippery * 2 if $self->{speedX} < 3;
    } else {
      $self->{speedX} = 3;
    }
    $self->{dir} = 1;
    $self->{state} = 'walk';
  } else {
    if ($slippery) {
      $self->{speedX} += $slippery if $self->{speedX} < 0;
      $self->{speedX} -= $slippery if $self->{speedX} > 0;
    }
  }
  $self->{x} += $self->{speedX};

  if ($self->{x} < -16) {
    $self->{x} = -16; $self->{speedX} = 0;
  }
  if ($self->{x} > $Games::PangZero::ScreenWidth - $self->{w} + 16) {
    $self->{x} = $Games::PangZero::ScreenWidth - $self->{w} + 16; $self->{speedX} = 0;
  }
}

sub Draw {
  my ($self) = @_;
  my ($surface, $srcrect, $srcx, $srcy, $srcw, $srch);

  return if ($self->{killed});
  $surface = $self->{surface};
  $surface = $self->{whiteSurface} if $self->{invincible} > 0 and (int($self->{invincible} / 2) % 3 == 0);

  $srcw = $srch = 64;
  if ($self->{state} eq 'idle') {
    $srcx = $self->{dir} * 128;
    $srcy = 64;
  } elsif ($self->{state} eq 'walk') {
    $srcx = $self->{dir} * $self->{animPhases} * 64 + (int($self->{x} / 50) % $self->{animPhases}) * 64;
    $srcy = 0;
  } elsif ($self->{state} eq 'demo') {
    $srcx = $self->{dir} * $self->{animPhases} * 64 + (int($Games::PangZero::Game->{anim} / 16) % $self->{animPhases}) * 64;
    $srcy = 0;
  } elsif ($self->{state} eq 'shoot') {
    $srcx = $self->{dir} * 128 + 64;
    $srcx -= 64 if ($self->{delay} <= 1);
    $srcy = 64;
  } elsif ($self->{state} eq 'fly') {
    $srcx = ($self->{dir} > 0 ? 0 : 64);
    $srcy = 128;
  }
  $srcrect = SDL::Rect->new($srcx, $srcy, $srcw, $srch );
  $self->TransferRect();
  SDL::Video::blit_surface($surface, $srcrect, $Games::PangZero::App, $self->{rect});
}

sub Kill {
  my ($self) = @_;

  return if $Games::PangZero::Cheat;
  return if $self->{invincible} > 0;
  $self->{justkilled} = 1;
  $Games::PangZero::GameEvents{'kill'} = 1;
  print "player killed\n" if $ENV{PANGZERO_TEST};
}

sub Earthquake {
  my ($self, $amplitude) = @_;

  return if $self->{state} eq 'fly';
  $self->{speedY} = -($amplitude->[0]);
  $self->{dir} = $amplitude->[1] > $self->{x} ? 0 : 1;
  $self->{state} = 'fly';
  $self->{y} -= 3;
}

sub DeleteHarpoons {
  my ($self) = @_;
  my (@gameObjects, $harpoon);

  @gameObjects = @Games::PangZero::GameObjects;
  foreach $harpoon (@gameObjects) {
    $harpoon->Delete if ($harpoon->{guy} and $harpoon->{guy} eq $self);
  }
}

sub GiveScore {
  my ($self, $score) = @_;

  my $player = $self->{player};
  $player->{score} += $score;
  if ($player->{score} >= $player->{scoreforbonuslife}) {
    ++$player->{lives};
    $player->{scoreforbonuslife} += 200000;
    Games::PangZero::PlaySound('bonuslife');
  }
}

1;
