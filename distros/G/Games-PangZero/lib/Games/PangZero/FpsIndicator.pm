##########################################################################
package Games::PangZero::FpsIndicator;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);

sub new {
  my ($class) = @_;
  my $self    = Games::PangZero::GameObject->new();
  my $width   = Games::PangZero::Graphics::TextWidth("999");
  %{$self}    = ( %{$self},
    'x' => $Games::PangZero::ScreenWidth - $width + $Games::PangZero::ScreenMargin,
    'y' => -$Games::PangZero::ScreenMargin,
    'w' => $width,
    'h' => 32,
  );
  
  $self->TransferRect();
  bless $self, $class;
}

sub Draw {
  my $self = shift;
  
  SDLx::SFont::print_text( $Games::PangZero::App, $self->{rect}->x, $self->{rect}->y, Games::PangZero::GameTimer::GetFramesPerSecond() );

}

1;
