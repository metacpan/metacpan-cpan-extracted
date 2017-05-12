##########################################################################
package Games::PangZero::MachineGun;
##########################################################################

@ISA = qw(Games::PangZero::Harpoon);
use strict;
use warnings;
use vars qw(@SrcRects);

@SrcRects = (
  SDL::Rect->new(  0, 160, 32, 32 ),
  SDL::Rect->new( 32, 160, 32, 32 ),
  SDL::Rect->new( 64, 160, 32, 32 ),
);

sub Create {
  return ( Games::PangZero::MachineGun->new(@_, 0), Games::PangZero::MachineGun->new(@_, 1), Games::PangZero::MachineGun->new(@_, 2) );
}

sub new {
  my ($class, $guy, $index) = @_;
  my ($self);

  $self = Games::PangZero::Harpoon->new($guy);
  %{$self} = ( %{$self},
    'x' => $guy->{x} + 16,
    'y' => $guy->{y} - 16,
    'w' => 32,
    'h' => 32,
    'index' => $index,
    'speedY' => -9,
    'speedX' => (-2, 0, 2)[$index],
  );
  bless $self, $class;
}

sub Delete {
  my $self = shift;

  --$self->{guy}->{harpoons} if $self->{index} == 1;
  delete $Harpoon::Harpoons{$self->{id}};
  $self->GameObject::Delete();
}

sub Advance {
  my $self = shift;

  if ($self->{y} < 0
    or $self->{x} < 0
    or $self->{x} > $Games::PangZero::ScreenWidth - $self->{w}) {
    $self->Delete();
    return;
  }
  $self->{y} += $self->{speedY};
  $self->{x} += $self->{speedX};
}

sub Draw {
  my $self = shift;

  $self->TransferRect();
  SDL::Video::blit_surface($self->{surface}, $SrcRects[$self->{index}], $Games::PangZero::App, $self->{rect});
}

1;
