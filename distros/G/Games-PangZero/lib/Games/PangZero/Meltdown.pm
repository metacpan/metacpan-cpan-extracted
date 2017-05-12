##########################################################################
package Games::PangZero::Meltdown;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);
use strict;
use warnings;

sub new {
  my ($class) = @_;
  my ($self, $surface);

  $self    = Games::PangZero::GameObject->new();
  $surface = SDL::Image::load( "$Games::PangZero::DataDir/meltdown.png" );
  %{$self} = ( %{$self},
    'x' => ($Games::PangZero::ScreenWidth - $surface->w) / 2,
    'y' => -$surface->h,
    'w' => $surface->w,
    'h' => $surface->h,
    'speedY' => 0,
    'surface' => $surface,
    'bounce' => 0,
  );
  bless $self, $class;
}

sub Advance {
  my $self = shift;
  $self->{speedY} += 0.1;
  $self->{y}      += $self->{speedY};
  
  if ($self->{bounce} == 0 and $self->{y} > $Games::PangZero::ScreenHeight - $self->{h}) {
    $self->{bounce} = 1;
    $self->{speedY} = -5;
    $self->{y}      = $Games::PangZero::ScreenHeight - $self->{h};
  }
  
  if ($self->{bounce} and $self->{y} > $Games::PangZero::PhysicalScreenHeight) {
    $self->Delete;
  }
}

sub Draw {
  my $self = shift;
  
  $self->TransferRect();
  SDL::Video::blit_surface($self->{surface}, SDL::Rect->new(0, 0, $self->{surface}->w, $self->{surface}->h), $Games::PangZero::App, $self->{rect} );
}

1;
