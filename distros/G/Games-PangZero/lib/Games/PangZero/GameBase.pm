##########################################################################
package Games::PangZero::GameBase;
##########################################################################

sub new {
  my ($class) = @_;
  my $self    = {
    abortgame   => 0,
    anim        => 0,
    nocollision => 0,
    backgrounds => [ 'desert2.png', ],
  };
  $Games::PangZero::GameSpeed = 1.0;
  $Games::PangZero::GamePause = 0;
  bless $self, $class;
}

sub Exit {
  Games::PangZero::ShowWebPage("http://apocalypse.rulez.org/pangzero/Thanks_For_Playing_Pang_Zero_$Games::PangZero::VERSION" ) if $Games::PangZero::ShowWebsite ne $Games::PangZero::VERSION;
  exit;
}

sub Rand {
  shift;
  return rand($_[0]);
}

sub Delay {
  my ($self, $ticks) = @_;

  while ($ticks > 0) {
    my $advance       = $self->CalculateAdvances();
    %Games::PangZero::Events = ();
    Games::PangZero::HandleEvents();
    return if $self->{abortgame};
    $ticks -= $advance;
    $self->DrawGame();
  }
}

sub SetGameSpeed {
}

sub SetBackground {
  my ($self, $backgroundIndex) = @_;

  return if $backgroundIndex >= scalar( @{$self->{backgrounds}} );
  Games::PangZero::Graphics::LoadBackground($self->{backgrounds}->[$backgroundIndex]);
  SDL::Video::blit_surface($Games::PangZero::Background, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h), $Games::PangZero::App, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h));
}

sub ShowTooltip {
}

sub ResetGame {
  my $self                      = shift;
  @Games::PangZero::GameObjects = ();
  %Guy::Guys                    = ();
  %Harpoon::Harpoons            = ();
  $Games::PangZero::GamePause   = 0;
  %Games::PangZero::GameEvents  = ();
  $self->SetBackground(0);
}

sub CalculateAdvances {
  my $advance = Games::PangZero::GameTimer::GetAdvances();
  while ($advance <= 0) {
    $Games::PangZero::App->delay(3); # Wait 3ms = 0.3 game ticks
    $advance = Games::PangZero::GameTimer::GetAdvances();
  }
  if ($advance > 5) {
    # print STDERR "advance = $advance!\n";
    $advance = 5;
  }
  return $advance;
}

sub AdvanceGameObjects {
  my ($self) = @_;

  ++$self->{anim};
  foreach my $gameObject (@Games::PangZero::GameObjects) {
    $gameObject->Advance();
  }
}

sub OnBallPopped {
}

sub DrawGame {
  my ($self) = @_;

  my ($gameObject);
  foreach $gameObject (@Games::PangZero::GameObjects) {
    $gameObject->Clear();
  }
  $self->DrawScoreBoard();
  foreach $gameObject (@Games::PangZero::GameObjects) {
    $gameObject->Draw();
  }
  $Games::PangZero::App->sync();
}

sub DrawScoreBoard {
}

1;
