##########################################################################
package Games::PangZero::PlaybackGame;
##########################################################################

@ISA = qw(Games::PangZero::PanicGame);
use strict;
use warnings;

sub new {
  my ($class, $numGuys, $difficultyLevel, $record, $rand, $messages) = @_;
  my $self = Games::PangZero::PanicGame->new();
  %{$self} = (%{$self},
    'record' => $record,
    'rand' => $rand,
    'messages' => $messages,
  );
  bless $self, $class;
  $self->InitPlayback($numGuys);
  Games::PangZero::Config::SetDifficultyLevel($difficultyLevel);
  return $self;
}

sub InitPlayback {
  my ($self, $numGuys)        = @_;
  $self->{recordpointer}      = 0;
  $self->{randpointer}        = 0;
  $self->{oldnumguys}         = $Games::PangZero::NumGuys;
  $self->{olddifficultylevel} = $Games::PangZero::DifficultyLevelIndex;
  $Games::PangZero::NumGuys          = $numGuys;
  
  for (my $i=0; $i < $numGuys; ++$i) {
    $Games::PangZero::Players[$i]->{oldkeys} = $Games::PangZero::Players[$i]->{keys};
    $Games::PangZero::Players[$i]->{keys}    = [ "DLEFT$i", "DRIGHT$i", "DFIRE$i" ];
  }
}

sub RestoreGameSettings {
  my $self = shift;
  
  for (my $i=0; $i < $Games::PangZero::NumGuys; ++$i) {
    $Games::PangZero::Players[$i]->{keys} = $Games::PangZero::Players[$i]->{oldkeys};
    delete $Games::PangZero::Players[$i]->{oldkeys};
  }
  $Games::PangZero::NumGuys = $self->{oldnumguys};
  Games::PangZero::Config::SetDifficultyLevel($self->{olddifficultylevel});
}

sub CalculateAdvances {
  my $self = shift;
  
  return length($self->{record}) if $self->{skip};
  return $self->SUPER::CalculateAdvances() * ($Games::PangZero::Keys{::SDLK_f()} ? 15 : 1);
}

sub Rand {
  my $self = shift;
  
  my $result = $self->{rand}->[$self->{randpointer}];
  ++$self->{randpointer};
  return $result;
}

sub PreAdvanceAction {
  my $self = shift;
  my ($record, $keys);

  for (my $i=0; $i < $Games::PangZero::NumGuys; ++$i) {

    $record = substr($self->{record}, $self->{recordpointer}++, 1);
    $keys = $Games::PangZero::Players[$i]->{keys};
    $Games::PangZero::Keys{$keys->[0]}      = $record & 1;
    $Games::PangZero::Keys{$keys->[1]}      = $record & 2;
    $Games::PangZero::Events{$keys->[2]}    = $record & 4;
    $Games::PangZero::GameEvents{superkill} = 1 if $Games::PangZero::NumGuys == 1 and $record & 8;
  }
  
  $self->{abortgame} = 1 if $self->{recordpointer} >= length $self->{record};
  
  if ($self->{messages}) {
    my $message =  $self->{messages}->{$self->{recordpointer}};
    $self->DisplayMessage($message) if $message;
  }
}

sub DisplayMessage {
  my ($self, $message) = @_;
  my ($len, $adv)      = (0, 0);
  my $x                = ( $Games::PangZero::PhysicalScreenWidth - &Games::PangZero::Graphics::TextWidth($message) ) / 2;
  my $y                = $Games::PangZero::PhysicalScreenHeight / 2;
  $self->DrawGame();

  while (1) {
    Games::PangZero::HandleEvents();
    return if $self->{abortgame};
    my $advance = $self->CalculateAdvances();
    $adv       += $advance;
    $len        = int($adv / 5);

    SDLx::SFont::print_text( $Games::PangZero::App,$x, $y, substr($message, 0, $len) );

    $Games::PangZero::App->sync();
    last if $len > length($message) + 15;
  }
  SDL::Video::blit_surface($Games::PangZero::Background, SDL::Rect->new(0, $y, $Games::PangZero::PhysicalScreenWidth, $y, 40), $Games::PangZero::App, SDL::Rect->new(0, $y, $Games::PangZero::App->w, $Games::PangZero::App->h));
}

1;
