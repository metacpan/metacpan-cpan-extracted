##########################################################################
package Games::PangZero::Harpoon;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);
use vars qw(%Harpoons $HarpoonId);

sub Create {
  return Games::PangZero::Harpoon->new(@_);
}

sub new {
  my ($class, $guy) = @_;
  my ($self);

  $self = Games::PangZero::GameObject->new();
  %{$self} = ( %{$self},
    'x' => $guy->{x} + 22,
    'y' => $Games::PangZero::ScreenHeight - 32,
    'w' => 18,
    'h' => 32,
    'speedY' => -3,
    'speedX' => 0,
    'guy' => $guy,
    'surface' => $guy->{player}->{harpoonSurface},
    'popEffect' => '',
    'id' => ++$HarpoonId,
  );
  $Harpoons{$self->{id}} =  $self;
  bless $self, $class;
}

sub Delete {
  my $self = shift;

  delete $Harpoons{$self->{id}};
  --$self->{guy}->{harpoons};
  $self->SUPER::Delete();
}

sub Advance {
  my $self = shift;

  if ($self->{y} < 0) {
    $self->Delete();
    return;
  }
  $self->{y} += $self->{speedY};
  $self->{h} = $Games::PangZero::ScreenHeight - $self->{y};
}

sub GetAnimPhase {
  my $self = shift;

  return (int($Games::PangZero::Game->{anim} / 4) % 3) + 1;
}

sub Draw {
  my $self = shift;
  my ($x, $y, $h, $maxh, $dstrect, $srcrect);

  $self->TransferRect();
  $y       = $self->{y};
  $dstrect = SDL::Rect->new( $self->{x} + $Games::PangZero::ScreenMargin, 0, $self->{w}, 0 );
  $srcrect = SDL::Rect->new( (0, 64, 32, 96)[ $self->GetAnimPhase() ], 0, $self->{w}, 0 );
  $maxh    = 160;

  # The harpoon needs to be drawn from tile pieces.
  # $y iterates from $self->{y} to $Games::PangZero::ScreenHeight
  # We draw at most $maxh height tiles at a time.

  while ($y < $Games::PangZero::ScreenHeight) {
    $h = $Games::PangZero::ScreenHeight - $y;
    $h = $maxh if $h > $maxh;
    $dstrect->y( $y + $Games::PangZero::ScreenMargin );
    $dstrect->h( $h );
    $srcrect->h( $h );
    SDL::Video::blit_surface($self->{surface}, $srcrect, $Games::PangZero::App, $dstrect );

    # Prepare for next piece
    $y += $h;
    $srcrect->y( 32 );      # First piece starts at 0, rest start at 32
    $maxh = 128;
  }
}

1;
