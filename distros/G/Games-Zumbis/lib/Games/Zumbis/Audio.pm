package Games::Zumbis::Audio;
BEGIN {
  $Games::Zumbis::Audio::VERSION = '0.05';
}

use strict;
use warnings;

use Carp ();
use SDL;
use SDL::Audio;
use SDL::Mixer;
use SDL::Mixer::Music;
use SDL::Mixer::Channels;
use SDL::Mixer::Samples;
use SDL::Mixer::MixChunk;

my $audio_ok = undef;

sub init {
    SDL::Mixer::open_audio( 44100, AUDIO_S16SYS, 2, 4096 );

    my ($status, $freq, $format, $channels) = @{ SDL::Mixer::query_spec() };

    Carp::carp ' Asked for freq, format, channels ' . join( ' ', ( 44100, AUDIO_S16SYS, 2,) );
    Carp::carp  ' Got back status,  freq, format, channels ' . join( ' ', ( $status, $freq, $format, $channels ) );

    $audio_ok = 1 if $status == 1;
}

sub play {
    my (undef, $chunk) = @_;
    return unless $chunk and $audio_ok;

    my $channel_number = SDL::Mixer::Channels::play_channel(-1, $chunk, 0 )
        or return;

    SDL::Mixer::Channels::volume( $channel_number, 10)
        if $channel_number >= 0;
}

sub pause {

}

sub inc_volume {

}

sub dec_volume {

}


sub load_sound {
    return unless $audio_ok;
    my (undef, $filename) = @_;
    return SDL::Mixer::Samples::load_WAV($filename);
}

sub start_music {
    return unless $audio_ok;
    my (undef, $filename) = @_;
    my $music = SDL::Mixer::Music::load_MUS($filename)
        or Carp::croak 'Music not found: ' . SDL::get_error();

    # play that funky music!
    SDL::Mixer::Music::play_music( $music, -1 );

    SDL::Mixer::Music::volume_music(85);
}

# close our audio on program ending.
# Note that this does *NOT* catch signals
# but then again, neither did our previous
# attempt :)
END {
    SDL::Mixer::close_audio();
}

42;
