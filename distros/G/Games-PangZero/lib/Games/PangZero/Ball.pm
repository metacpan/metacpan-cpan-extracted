##########################################################################
package Games::PangZero::Ball;
##########################################################################

use Games::PangZero::Globals;

@ISA           = qw(Games::PangZero::GameObject);
$Gravity       = 0.05;
$MagicBallRect = SDL::Rect->new(80, 0, 16, 15);

for (my $i = 0; $i <= $#Games::PangZero::BallDesc; ++$i) {
  my $desc = $Games::PangZero::BallDesc[$i];
  $desc->{speedY}  = 0 unless $desc->{speedY};
  $desc->{bounceY} = $desc->{speedY} * $desc->{speedY} / $Games::PangZero::Ball::Gravity / 2 unless $desc->{bounceY};
}

sub Create {
  my ($description, $x, $y, $dir) = @_;
  my ($retval);

  my $code  = sprintf('$retval = Games::PangZero::%s->new(@_);', $description->{class});
  eval $code; die $@ if $@;
  return $retval;
}

sub Spawn {
  my ($description, $x, $dir, $hasBonus) = @_;
  my ($retval);
  
  $x      = $Games::PangZero::Game->Rand( $Games::PangZero::ScreenWidth - $description->{width} ) if $x < 0;
  $retval = Games::PangZero::Ball::Create( $description, $x, -$description->{height} - $Games::PangZero::ScreenMargin, $dir );
  $retval->GiveMagic() if $retval->{w} > 32;
  $retval->GiveBonus() if $hasBonus;

  $retval->{spawning} = 1;
  my $surfaceName     = 'dark' . $description->{surface};
  $retval->{surface}  = $Games::PangZero::BallSurfaces{$surfaceName};
  die "No surface: $surfaceName" unless $retval->{surface};
  return $retval;
}

sub new {
  my ($class, $description, $x, $y, $dir) = @_;
  my $self                                = Games::PangZero::GameObject->new();
  %{$self}                                = ( %{$self},
    'x'        => $x,
    'y'        => $y,
    'w'        => $description->{width},
    'h'        => $description->{height},
    'surface'  => $Games::PangZero::BallSurfaces{$description->{surface}},
    'hexa'     => $description->{hexa} ? 1 : 0,
    'desc'     => $description,
    'hasmagic' => 0,         # true if one of the ball's descendants is magic
    'ismagic'  => 0,         # true if the ball IS magic
    'spawning' => 0,
  );
  $self->{speedX} = $dir > 0 ? 1.3 : -1.3;
  $self->SetupCollisions();
  bless $self, $class;
}

sub NormalAdvance {
  my $self = shift;
  
  $self->{speedY} += $Games::PangZero::Ball::Gravity * $Games::PangZero::GameSpeed unless ($self->{hexa});
  $self->{x}      += $self->{speedX} * $Games::PangZero::GameSpeed;
  $self->{y}      += $self->{speedY} * $Games::PangZero::GameSpeed;
  if ($self->{y} > $Games::PangZero::ScreenHeight - $self->{h}) {
    $self->{y} = $Games::PangZero::ScreenHeight - $self->{h};
    if ($self->{hexa}) {
      $self->{speedY} = -abs($self->{speedY});
    } else {
      $self->{speedY} = -$self->{desc}->{speedY};
    }
    $self->Bounce;
  }
  if ($self->{y} < 0) {
    $self->{y}      = 0;
    $self->{speedY} = abs($self->{speedY});
  }
  if ($self->{x} < 0) {
    $self->{x}      = 0;
    $self->{speedX} = abs( $self->{speedX} );
  }
  if ($self->{x} > $Games::PangZero::ScreenWidth - $self->{w}) {
    $self->{x}      = $Games::PangZero::ScreenWidth - $self->{w};
    $self->{speedX} = -abs( $self->{speedX} );
  }
}

sub SpawningAdvance {
  my $self = shift;

  $self->{y} += 0.32;
  if ($self->{y} >= 0) {
    $self->{spawning} = 0;
    $self->{surface} = $Games::PangZero::BallSurfaces{$self->{desc}->{surface}},
  }
}

sub Advance {
  my $self = shift;

  unless( $Games::PangZero::GamePause > 0 ) {
    if ($self->{spawning}) {
      $self->SpawningAdvance();
    } else {
      $self->NormalAdvance();
    }
  }

  $self->CheckCollisions() unless $Games::PangZero::Game->{nocollision} or $self->{spawning};
}

sub Bounce {
}

sub CheckCollisions {
  my $self = shift;

  foreach my $harpoon (values %Games::PangZero::Harpoon::Harpoons) {
    if ($self->Collisions($harpoon)) {
      $self->Pop($harpoon->{guy}, $harpoon->{popEffect});
      $harpoon->Delete();
      return;
    }
  }
  foreach my $guy (values %Games::PangZero::Guy::Guys) {
    if ($Games::PangZero::GamePause <= 0 and $self->Collisions($guy)) {
      $guy->Kill();
    }
  }
}

sub Draw {
  my ($self) = @_;

  return if $Games::PangZero::GamePause > 0 and $Games::PangZero::GamePause < 100 and (int($Games::PangZero::GamePause / 3) % 4) < 2;
  
  $self->TransferRect();
  if ($self->{ismagic} and int($Games::PangZero::Game->{anim}/4) % 2) {
    SDL::Video::blit_surface($Games::PangZero::BallSurfaces{ball4}, $Games::PangZero::Ball::MagicBallRect, $Games::PangZero::App, $self->{rect} );
  } else {
    SDL::Video::blit_surface($self->{surface}, $self->{desc}->{rect}, $Games::PangZero::App, $self->{rect} );
  }
}

sub Collisions {
  my ($self, $other) = @_;

  # Bounding box detection

  return unless $self->SUPER::Collisions($other);

  # Circle vs rectangle collision

  my ($centerX, $centerY, $boxAxisX, $boxAxisY, $boxCenterX, $boxCenterY, $distSquare, $distance);
  $boxAxisX   = ($other->{collisionw} or $other->{w}) / 2;
  $boxAxisY   = ($other->{collisionh} or $other->{h}) / 2;
  $boxCenterX = $other->{x} + $other->{w} / 2;
  $boxCenterY = $other->{y} + $other->{h} / 2;
  $centerX    = $self->{x} + $self->{w} / 2;
  $centerY    = $self->{y} + $self->{h} / 2;

  # Translate coordinates to the box center
  $centerX -= $boxCenterX;
  $centerY -= $boxCenterY;
  $centerX  = abs($centerX);
  $centerY  = abs($centerY);

  if ($centerX < $boxAxisX) {
    return 1 if $centerY < $boxAxisY + $self->{h} / 2;
    return 0;
  }
  if ($centerY < $boxAxisY) {
    return 2 if $centerX < $boxAxisX + $self->{w} / 2;
    return 0;
  }
  $distSquare  = ($centerX-$boxAxisX) * ($centerX-$boxAxisX);
  $distSquare += ($centerY-$boxAxisY) * ($centerY-$boxAxisY);
  return 3 if $distSquare < $self->{h} * $self->{h} / 4;

  return 0;
}

sub Pop {
  my ($self, $guy, $popEffect) = @_;

  Carp::confess "no $popEffect" unless defined $popEffect;
  $Games::PangZero::GameEvents{'pop'}   = 1;
  $Games::PangZero::GameEvents{'magic'} = 1 if ($self->{ismagic});
  $guy->GiveScore($self->{desc}->{score}) if $guy;
  $self->Delete();
  
  goto skipChildren if ($popEffect eq 'meltdown');
  
  if ($self->{desc}->{nextgen}) {
    die caller unless $self->{desc}->{nextgen}->{class};
    my @children = $self->SpawnChildren();
    if (scalar @children) {
      $self->AdjustChildren(@children);
      if ($popEffect eq 'HalfCutter') {
        push @Games::PangZero::GameObjects, ($self->{speedX} > 0 ? $children[1] : $children[0]);
      } else {
        push @Games::PangZero::GameObjects, (@children);
      }
    }
  }
  if ($self->{bonus} and $popEffect ne 'superkill') {
    push @Games::PangZero::GameObjects, Games::PangZero::BonusDrop->new($self);
  }
  $Games::PangZero::Game->OnBallPopped();
  
  skipChildren:
  push @Games::PangZero::GameObjects, Games::PangZero::Pop->new($self->{x}, $self->{y}, $self->{desc}->{popIndex}, $self->{surface});
}

sub SpawnChildren {
  my $self    = shift;
  my $nextgen = $self->{desc}->{nextgen};
  die caller unless $nextgen->{class};
  my $x       = $self->{x} + $self->{w} / 2;
  my $y       = $self->{y} + ( $self->{h} - $nextgen->{height} ) / 2;
  my $child1  = Create($nextgen, $self->{x}, $y, 0);
  my $child2  = Create($nextgen, $self->{x} + $self->{w} - $nextgen->{width}, $y, 1);
  
  return ($child1, $child2);
}

sub AdjustChildren {
  my ($self, @children) = @_;
  my ($nextgen, $speedY, $altitude);

  if ($self->{hasmagic}) {
    $children[0]->GiveMagic();
  }

  $nextgen  = $self->{desc}->{nextgen};
  $altitude = $Games::PangZero::ScreenHeight - $self->{y} - $self->{h};
    $speedY = 1.8;
  unless ($altitude > $nextgen->{bounceY}) {
    $speedY = 1.8;
    while ($speedY * $speedY / $Games::PangZero::Ball::Gravity / 2 + $altitude < $nextgen->{bounceY}) {
      ++$speedY;
    }
  }
  foreach (@children) {
    $_->{speedY} = -$speedY;
  }
}

sub GiveMagic {
  my $self = shift;

  $self->{hasmagic} = 1;
  $self->{ismagic}  = 1 unless $self->{desc}->{nextgen};
}

sub GiveBonus {
  my $self = shift;

  $self->{bonus} = 1;
}

1;
