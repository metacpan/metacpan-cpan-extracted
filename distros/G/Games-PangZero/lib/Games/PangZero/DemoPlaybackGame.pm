##########################################################################
package Games::PangZero::DemoPlaybackGame;
##########################################################################

@ISA = qw(Games::PangZero::DemoGame Games::PangZero::PlaybackGame);
use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = Games::PangZero::PlaybackGame->new(@_);
  bless $self, $class;
}

sub DrawScoreBoard {
  my $self = shift;
  my $x    = 10;
  my $y    = $Games::PangZero::ScreenHeight + 2 * $Games::PangZero::ScreenMargin + 5;
  if ($self->{anim} < 1) {
    SDLx::SFont::print_text(   $Games::PangZero::Background, $x, $y, "Press F to fast forward" );
    SDLx::SFont::print_text(   $Games::PangZero::App, $x, $y, "Press F to fast forward" );
  } return;
  SDL::Video::fill_rect($Games::PangZero::App, SDL::Rect->new(0, $y, $Games::PangZero::PhysicalScreenWidth, $Games::PangZero::PhysicalScreenHeight - $y), SDL::Color->new(0, 0, 0) );
  SDLx::SFont::print_text( $Games::PangZero::App, $x, $y, $self->{recordpointer} );

}
