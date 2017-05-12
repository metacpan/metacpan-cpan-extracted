##########################################################################
package Games::PangZero::Hexa;
##########################################################################

@ISA = qw(Games::PangZero::Ball);

sub new {
  my $class       = shift;
  my $self        = Games::PangZero::Ball->new(@_);
  $self->{speedX} = ($Games::PangZero::Game->Rand(1.25) + 1.25) * ($self->{speedX} > 0 ? 1 : -1);
  $self->{speedY} = -4 + abs($self->{speedX});

  bless $self, $class;
}

sub Draw {
  my $self = shift;
  my ($rect, $srcx, $phase);

  return if $Games::PangZero::GamePause > 0 and $Games::PangZero::GamePause < 100 and (int($Games::PangZero::GamePause / 3) % 4) < 2;
  
  $self->TransferRect();
  if ($self->{ismagic} and int($Games::PangZero::Game->{anim} / 3) % 3 == 0) {
    SDL::Video::blit_surface($self->{surface}, $self->{desc}->{magicrect}, $Games::PangZero::App, $self->{rect});
  } else {
    $rect  = $self->{desc}->{rect};
    $phase = int($Games::PangZero::Game->{anim} / 5) % 3;
    $phase = 2 - $phase if $self->{speedX} < 0;
    $srcx  = $phase * $self->{w};
    $rect->x( $rect->x + $srcx );
    SDL::Video::blit_surface($self->{surface}, $rect, $Games::PangZero::App, $self->{rect} );
    $rect->x( $rect->x - $srcx );
  }
}

sub AdjustChildren {
  my ($self, $child1, $child2) = @_;
  if ($self->{hasmagic}) {
    $child2->GiveMagic();
  }
}

1;
