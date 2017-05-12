##########################################################################
package Games::PangZero::GameObject;
##########################################################################

sub new {
  my ($class) = @_;
  my $self    = {
    'rect'   => SDL::Rect->new( 0, 0, 0, 0 ),
    'speedX' => 0,
    'speedY' => 0,
    'x'      => 0,
    'y'      => 0,
    'w'      => 10,
    'h'      => 10,
  };
  bless $self, $class;
}

sub Delete {
  my $self = shift;

  for (my $i = 0; $i < scalar @Games::PangZero::GameObjects; ++$i) {
    if ($Games::PangZero::GameObjects[$i] eq $self) {
      splice @Games::PangZero::GameObjects, $i, 1;
      last;
    }
  }
  $self->{deleted} = 1;
  $self->Clear();
}

sub Advance {
  my $self = shift;
  
  $self->{advance}->($self) if $self->{advance};
}

sub Clear {
  my ($self) = @_;
  SDL::Video::blit_surface($Games::PangZero::Background, $self->{rect}, $Games::PangZero::App, $self->{rect});
}

sub TransferRect {
  my ($self) = @_;

  $self->{rect}->x($self->{x} + $Games::PangZero::ScreenMargin);
  $self->{rect}->y($self->{y} + $Games::PangZero::ScreenMargin);
  $self->{rect}->w($self->{w});
  $self->{rect}->h($self->{h});
}

sub Draw {
  my ($self) = @_;

  $self->TransferRect();
  if ($self->{draw}) {
    $self->{draw}->($self);
  } else {
    SDL::Video::fill_rect( $Games::PangZero::App, $self->{rect}, SDL::Color->new(0x80, 0, 0) );
  }
}

sub SetupCollisions {
  my ($self) = @_;
  
  $self->{collisionw}        = ($self->{collisionw} or $self->{w});
  $self->{collisionh}        = ($self->{collisionh} or $self->{h});
  $self->{collisionmarginw1} = ( $self->{w} - $self->{collisionw} ) / 2;
  $self->{collisionmarginw2} = $self->{collisionmarginw1} + $self->{collisionw};
  $self->{collisionmarginh1} = ( $self->{h} - $self->{collisionh} ) / 2;
  $self->{collisionmarginh2} = $self->{collisionmarginh1} + $self->{collisionh};
  $self->{centerx}           = $self->{w} / 2;
  $self->{centery}           = $self->{y} / 2;
}

sub Collisions {
  my ($self, $other) = @_;
  
  # Bounding box detection
  
  unless ($self->{collisionmarginw1} and $other->{collisionmarginw1}) {
    return 0 if $self->{x}  >= $other->{x} + $other->{w};
    return 0 if $other->{x} >= $self->{x}  + $self->{w};
    return 0 if $self->{y}  >= $other->{y} + $other->{h};
    return 0 if $other->{y} >= $self->{y}  + $self->{h};
    return 1;
  }
  
  return 0 if $self->{x}  + $self->{collisionmarginw1}  >= $other->{x} + $other->{collisionmarginw2};
  return 0 if $other->{x} + $other->{collisionmarginw1} >= $self->{x}  + $self->{collisionmarginw2};
  return 0 if $self->{y}  + $self->{collisionmarginh1}  >= $other->{y} + $other->{collisionmarginh2};
  return 0 if $other->{y} + $other->{collisionmarginh1} >= $self->{y}  + $self->{collisionmarginh2};
  return 1;
}

1;
