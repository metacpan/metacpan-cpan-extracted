package Games::PangZero::Music;

use SDL::Mixer;
use SDL::Mixer::Samples;
use SDL::Mixer::Channels;
use SDL::Mixer::Music;
use SDL::Mixer::MixChunk;
use SDL::Mixer::MixMusic;

sub LoadMusic {
  my ($filename) = @_;
  
  return undef unless -f $filename;
  return SDL::Mixer::Music::load_MUS($filename);
}

sub LoadSounds {
  $Mixer = SDL::Mixer::open_audio( 22050, AUDIO_S16, 2, 1024 ) + 1;
  unless($Mixer) {
    warn SDL::get_error();
    return 0;
  }

  my ($soundName, $fileName);
  while (($soundName, $fileName) = each %Sounds) {
    $Sounds{$soundName} = SDL::Mixer::Music::load_WAV("$Games::PangZero::DataDir/$fileName");
  }

  $Games::PangZero::music = LoadMusic("$Games::PangZero::DataDir/UPiPang.mp3");
  $Games::PangZero::music = LoadMusic("$Games::PangZero::DataDir/UPiPang.mid") unless $Games::PangZero::music;
  SetMusicEnabled($MusicEnabled);
}

sub PlaySound {
  return unless $SoundEnabled;
  my $sound = shift;
  $Mixer and $Sounds{$sound} and SDL::Mixer::Channels::play_channel( -1, $Sounds{$sound}, 0 );
}

sub SetMusicEnabled {
  return $MusicEnabled = 0 unless $Games::PangZero::music;
  my $musicEnabled = shift;

  $MusicEnabled = $musicEnabled ? 1 : 0;
  if ( (not $MusicEnabled) and SDL::Mixer::Music::playing_music() ) {
    SDL::Mixer::Music::halt_music();
  }
  if ($MusicEnabled and not SDL::Mixer::Music::playing_music()) {
    SDL::Mixer::Music::play_music($Games::PangZero::music, -1);
  }
}

1;
