##########################################################################
package Games::PangZero::SeekerBall;
##########################################################################

@ISA = qw( Games::PangZero::Ball );
use strict;
use warnings;

sub new {
  my $class       = shift;
  my $self        = Games::PangZero::Ball->new(@_);
  my @guys        = grep {ref $_ eq 'Games::PangZero::Guy'} @Games::PangZero::GameObjects;
  $self->{target} = $guys[$Games::PangZero::Game->Rand(scalar @guys)];
  $self->{deltaX} = (-$self->{w} + $self->{target}->{w}) / 2;
  die unless $self->{target};

  bless $self, $class;
}

sub NormalAdvance {
  my $self = shift;
  
  my $multiplier = ($self->{y} > $Games::PangZero::ScreenHeight - 120) ? 0 : 25;
  unless( $Games::PangZero::GamePause > 0 ) {
    if ($self->{x} + $self->{speedX} * $multiplier > $self->{target}->{x} + $self->{deltaX}) {
      $self->{speedX} -= 0.08;
    } else {
      $self->{speedX} += 0.08;
    }
  }
  $self->SUPER::NormalAdvance();
}

sub AdjustChildren {
  my ($self, $child1, $child2) = @_;
  
  $self->SUPER::AdjustChildren($child1, $child2);
  $child1->{speedX} *= 2;
  $child1->{deltaX} -= 30;
  $child1->{target}  = $self->{target};
  $child2->{speedX} *= 2;
  $child2->{deltaX} += 30;
  $child2->{target}  = $self->{target};
}

sub GiveMagic {
}

sub Draw {
  my $self = shift;
  
  $self->SUPER::Draw();
  my $guySurface = $self->{target}->{player}->{guySurface};
  my $srcrect    = ($self->{w} <= 32)
                 ? SDL::Rect->new(320, 176, 16, 16)
                 : SDL::Rect->new(320, 128, 32, 32);
  my $dstrect    = SDL::Rect->new(
    $self->{x} + $Games::PangZero::ScreenMargin + ($self->{w} - $srcrect->w()) / 2, 
    $self->{y} + $Games::PangZero::ScreenMargin + ($self->{h} - $srcrect->h()) / 2 + 2, $srcrect->w, $srcrect->h);
  SDL::Video::blit_surface($guySurface, $srcrect, $Games::PangZero::App, $dstrect);
}

1;
