##########################################################################
package Games::PangZero::DeadGuy;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);
use strict;
use warnings;

sub new {
  my ($class, $guy, $dir) = @_;
  my ($self, $player);

  $self   = Games::PangZero::GameObject->new();
  $player = $guy->{player};

  %{$self} = ( %{$self},
    'x' => $guy->{x},
    'y' => $guy->{y},
    'w' => 64,
    'h' => 64,
    'speedY' => -7,
    'surface' => $player->{guySurface},
    'anim' => 0,
    'bounce' => 0,
    'bouncex' => 0,
  );
  $self->{'speedX'} = ($Games::PangZero::Game->Rand(2) + 1.5) * (($self->{x} > $Games::PangZero::ScreenWidth / 2) ? 1 : -1);
  bless $self, $class;
}

sub Advance {
  my $self = shift;

  $self->{speedY} += 0.1;
  $self->{x} += $self->{speedX};
  $self->{y} += $self->{speedY};
  
  unless ($self->{bouncex}) {
    if ($self->{x} < -16) {
      $self->{x} = -16;
      $self->{speedX} = abs( $self->{speedX} );
      $self->{speedY} = -3 if $self->{speedY} > -3;
      $self->{bouncex} = 1;
    }
    if ($self->{x} > $Games::PangZero::ScreenWidth - $self->{w} +16) {
      $self->{x} = $Games::PangZero::ScreenWidth - $self->{w} + 16;
      $self->{speedX} = -abs( $self->{speedX} );
      $self->{speedY} = -3 if $self->{speedY} > -3;
      $self->{bouncex} = 1;
    }
  }
  if ($self->{y} > $Games::PangZero::ScreenHeight - 64 and not $self->{bounce}) {
    $self->{bounce} = 1;
    $self->{speedY} = -3;
  }

  if ($self->{y} > $Games::PangZero::PhysicalScreenHeight) {
    $self->Delete;
  }
  $self->{anim} += $self->{speedX} > 0 ? -1 : +1;
}

sub Draw {
	my $self = shift;
	my ($srcrect);

	$srcrect = SDL::Rect->new(($self->{speedX} > 0 ? 0 : 64), 128, 64, 64 );
	$self->TransferRect();
	if(SDL::Config->has('SDL_gfx_rotozoom')) {
		my $roto = SDL::Surface->new( SDL::Video::SDL_SWSURFACE(), 64, 64, 32, 0xFF000000, 0xFF0000, 0xFF00, 0xFF);
		SDL::Video::blit_surface($self->{surface}, $srcrect, $roto, SDL::Rect->new(0, 0, $roto->w, $roto->h) );
		$roto = SDL::GFX::Rotozoom::surface($roto, $self->{anim} * 5, 1, SDL::GFX::Rotozoom::SMOOTHING_OFF());
		$self->{rect}->x( $self->{rect}->x - ($roto->w  - 64) / 2 );
		$self->{rect}->y( $self->{rect}->y - ($roto->h - 64) / 2 );
		SDL::Video::blit_surface($roto, SDL::Rect->new(0, 0, 64, 64), $Games::PangZero::App, $self->{rect} );
		return;
	}
	else {
		SDL::Video::blit_surface($self->{surface}, $srcrect, $Games::PangZero::App, $self->{rect} );
	}
}

1;
