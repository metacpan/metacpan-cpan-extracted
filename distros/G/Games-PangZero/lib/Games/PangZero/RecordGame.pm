##########################################################################
package Games::PangZero::RecordGame;
##########################################################################

@ISA = qw(Games::PangZero::PanicGame);
use strict;
use warnings;

sub Rand {
  my $self = shift;
  my $result = int(rand($_[0]) * 100) / 100;
  push @{$self->{rand}}, ($result);
  return $result;
}

sub Rewind {
  my $self = shift;
  my ($recordEnd, $playback);
  
  $recordEnd = length($self->{record}) - $Games::PangZero::NumGuys * 1000;
  return if $recordEnd <= 0;
  $self->{record}   = substr($self->{record}, 0, $recordEnd);
  $Games::PangZero::Game   = $playback
                    = DemoPlaybackGame->new($Games::PangZero::NumGuys, $Games::PangZero::DifficultyLevel, $self->{record}, $self->{rand}, {});
  $playback->{skip} = 1;
  SDL::Video::blit_surface($Games::PangZero::Background, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h), $Games::PangZero::App, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h));
  $playback->Run();
  
  $playback->RestoreGameSettings();
  %{$self}           = %{$playback};
  $Games::PangZero::Game    = $self;
  $self->{abortgame} = 0;
  print "Splicing {rand}: original length is ", scalar(@{$self->{rand}}), "; playback randpointer is $playback->{randpointer}.\n";
  splice @{$self->{rand}}, $playback->{randpointer};
  SDL::Video::blit_surface($Games::PangZero::Background, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h), $Games::PangZero::App, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h));
  $self->DrawGame();
  %Games::PangZero::Events = %Games::PangZero::Keys = ();
  
  while( not %Games::PangZero::Events ) {
    Games::PangZero::HandleEvents();
    $Games::PangZero::App->delay(100);
  }
  GameTimer::ResetTimer();
}

sub PreAdvanceAction {
  my $self = shift;
  $self->Rewind() if $Games::PangZero::Events{::SDLK_F3()};
  
  for (my $i = 0; $i < $Games::PangZero::NumGuys; ++$i) {
    my $keys = $Games::PangZero::Players[$i]->{keys};
    my $record = 0;
    $record   += 1 if $Games::PangZero::Keys{$keys->[0]};
    $record   += 2 if $Games::PangZero::Keys{$keys->[1]};
    $record   += 4 if $Games::PangZero::Events{$keys->[2]};
    if ($Games::PangZero::Events{SDLK_F2()} and $Games::PangZero::NumGuys == 1) {
      $record += 8;
      $Games::PangZero::GameEvents{superkill} = 1;
    }
    $self->{record} .= $record;
  }
}

1;
