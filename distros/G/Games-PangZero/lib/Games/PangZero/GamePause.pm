##########################################################################
package Games::PangZero::GamePause;
##########################################################################

@ISA = qw(Games::PangZero::GameObject);

sub Show {
  foreach my $gameObject (@Games::PangZero::GameObjects) {
    return if (ref $gameObject eq 'Games::PangZero::GamePause');
  }
  push @Games::PangZero::GameObjects, Games::PangZero::GamePause->new();
}

sub new {
  my ($class) = @_;
  my $self    = Games::PangZero::GameObject->new();
  my $width   = Games::PangZero::Graphics::TextWidth("Time left: 9.999");
  %{$self}    = ( %{$self},
    'x' => ($Games::PangZero::PhysicalScreenWidth - $width) / 2,
    'y' => 100,
    'w' => $width,
    'h' => 32,
  );
  $self->TransferRect();
  bless $self, $class;
}

sub BringToFront {
  my $self = shift;

  @Games::PangZero::GameObjects = grep { $_ ne $self } @Games::PangZero::GameObjects;
  push @Games::PangZero::GameObjects, ($self);
}

sub Advance {
  my $self = shift;

  if ($Games::PangZero::GamePause <= 0) {
    $self->Delete;
    return;
  }
  unless ($Games::PangZero::GameObjects[$#Games::PangZero::GameObjects] eq $self) {
    $self->BringToFront();
  }
}

sub Draw {
  my $self = shift;

  SDLx::SFont::print_text( $Games::PangZero::App, $self->{rect}->x, $self->{rect}->y, "Time left: " . ($Games::PangZero::GamePause / 100) );

}

1;
