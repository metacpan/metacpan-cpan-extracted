package Games::HotPotato;
BEGIN {
  $Games::HotPotato::VERSION = '0.110020';
}
use Moose;
# ABSTRACT: A random length hot-potato timer with a dramatic ending

use Config::INI::Reader;
use DateTime::Duration;
use MooseX::Types::DateTime;
use MooseX::Types::Path::Class;
use Path::Class qw( dir file );

use SDL::Mixer;
use SDL::Mixer::Music;


has minimum_time => (
    is          => 'rw',
    isa         => 'DateTime::Duration',
    coerce      => 1,
    lazy        => 1,
    default     => sub { DateTime::Duration->new( seconds => 20 ) },
);


has maximum_time => (
    is          => 'rw',
    isa         => 'DateTime::Duration',
    coerce      => 1,
    lazy        => 1,
    default     => sub { DateTime::Duration->new( seconds => 40 ) },
);


has minimum_rush => (
    is          => 'rw',
    isa         => 'DateTime::Duration',
    coerce      => 1,
    lazy        => 1,
    default     => sub { DateTime::Duration->new( seconds => 5 ) },
);


has maximum_rush => (
    is          => 'rw',
    isa         => 'DateTime::Duration',
    coerce      => 1,
    lazy        => 1,
    default     => sub { DateTime::Duration->new( seconds => 15 ) },
);


has sound_theme => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'zostay',
);


has start_alert => (
    is          => 'rw',
    isa         => 'Path::Class::File',
    required    => 1,
    coerce      => 1,
    lazy_build  => 1,
);

sub _build_start_alert {
    my $self = shift;
    $self->path_from_sound_theme('start_alert');
}


has rush_alert => (
    is          => 'rw',
    isa         => 'Path::Class::File',
    required    => 1,
    coerce      => 1,
    lazy_build  => 1,
);

sub _build_rush_alert {
    my $self = shift;
    $self->path_from_sound_theme('rush_alert');
}


has final_alert => (
    is          => 'rw',
    isa         => 'Path::Class::File',
    required    => 1,
    coerce      => 1,
    lazy_build  => 1,
);

sub _build_final_alert {
    my $self = shift;
    $self->path_from_sound_theme('final_alert');
}


has start_music => (
    is          => 'rw',
    isa         => 'Path::Class::File',
    required    => 1,
    coerce      => 1,
    lazy_build  => 1,
);

sub _build_start_music {
    my $self = shift;
    $self->path_from_sound_theme('start_music');
}


has rush_music => (
    is          => 'rw',
    isa         => 'Path::Class::File',
    required    => 1,
    coerce      => 1,
    lazy_build  => 1,
);

sub _build_rush_music {
    my $self = shift;
    $self->path_from_sound_theme('rush_music');
}


has config => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    lazy_build  => 1,
);

sub _build_config {
    my $self = shift;

    my $base_config = Config::INI::Reader->read_handle(\*DATA);    
    my %config      = %$base_config;

    if (-f "$ENV{HOME}/.hotpotato/config.ini") {
        my $user_config = Config::INI::Reader->read_file("$ENV{HOME}/.hotpotato/config.ini");
        %config = ( %config, %$user_config );
    }

    return \%config;
}


sub path_from_sound_theme {
    my ($self, $value_name) = @_;

    my $theme_name = $self->sound_theme;
    my $file = $self->config->{"sounds $theme_name"}{$value_name};
    my $path = $self->locate_file($file);
    return $path;
}


sub locate_file {
    my ($self, $file) = @_;

    my @bases = (
        file(__FILE__)->dir->subdir('HotPotato'),
        dir("$ENV{HOME}", ".hotpotato"),
    );

    for my $base (@bases) {
        my $possible_path = $base->file($file);
        return $possible_path if -e $possible_path;
    }

    die "cannot locate file $file in any of these locations: ",
        join(" ", @bases), "\n";
}


sub random_time {
    my ($self, $min, $max) = @_;

    my $min_secs = $min->seconds;
    my $max_secs = $max->seconds;

    return int( $min_secs + rand( $max_secs - $min_secs ) );
}


sub run {
    my $self = shift;

    my $time = $self->random_time($self->minimum_time, $self->maximum_time);
    my $rush = $self->random_time($self->minimum_rush, $self->maximum_rush);

    #print "Time = $time seconds\n";
    #print "Rush = $rush seconds\n";

    SDL::Mixer::open_audio(44100, AUDIO_S16SYS, 2, 4096);
    my ($status) = @{ SDL::Mixer::query_spec() };

    die "unable to initialize mixer\n" unless $status;

    SDL::Mixer::Music::volume_music(100);

    my $start_alert = SDL::Mixer::Music::load_MUS($self->start_alert);
    SDL::Mixer::Music::play_music($start_alert, 0);

    my $start_music = SDL::Mixer::Music::load_MUS($self->start_music);
    SDL::Mixer::Music::play_music($start_music, -1);

    sleep($time - $rush);

    SDL::Mixer::Music::halt_music();

    my $rush_alert = SDL::Mixer::Music::load_MUS($self->rush_alert);
    SDL::Mixer::Music::play_music($rush_alert, 0);

    my $rush_music = SDL::Mixer::Music::load_MUS($self->rush_music);
    SDL::Mixer::Music::play_music($rush_music, -1);

    sleep($rush);

    SDL::Mixer::Music::halt_music();

    my $final_alert = SDL::Mixer::Music::load_MUS($self->final_alert);
    SDL::Mixer::Music::play_music($final_alert, 0);

    sleep 1 while SDL::Mixer::Music::playing_music();
}


1;



=pod

=head1 NAME

Games::HotPotato - A random length hot-potato timer with a dramatic ending

=head1 VERSION

version 0.110020

=head1 SYNOPSIS

  use Games::HotPotato;

  my $hot_potato = Games::HotPotato->new;

  $hot_potato->minimum_time({ seconds => 20 });
  $hot_potato->maximum_time({ seconds => 40 });
  $hot_potato->maximum_rush({ seconds => 15 });
  $hot_potato->minimum_rush({ seconds => 5 });

  $hot_potato->start_alert('bing.wav');
  $hot_potato->start_music('calm.wav');
  $hot_potato->start_rush_alert('dumdumdum.wav');
  $hot_potato->rush_music('urgent.wav');
  $hot_potato->final_alert('crash.wav');

  $hot_potato->run;

=head1 DESCRIPTION

This class holds the internals for the F<hot-potato> game. See L<hot-potato>.

=head1 ATTRIBUTES

=head2 minimum_time

This is the minimum duration for the hot potato timer. Default is 20 seconds.

=head2 maximum_time

This is the maximum duration for the hot potato timer. Defaut is 40 seconds. This must be greater than or equal to L</minumum_time>.

=head2 minimum_rush

This is the minimum duration for the rush time. Default is 5 seconds. This must be less than the L</minimum_time>.

=head2 maximum_rush

This is the maximum duration for the rush time. Default is 15 seconds. This must be greater than or equal to L</minimum_rush> and must be less than the L</minimum_time>.

=head2 sound_theme

This is the sound theme to use. This is set to "zostay" by default.

=head2 start_alert

This is the sound to play to announce that the game has begun.

=head2 rush_alert

This is the sound to play when the rush starts.

=head2 final_alert

This is the sound to announce that the game is over.

=head2 start_music

This is the sound or music to play and repeat at the start of the game after the L</start_alert> is played.

=head2 rush_music

This is the sound or music to play and repeat during the rush at the end of the game after the L</rush_alert> is played.

=head2 config

This contains a hash of configuration information for the game.

The configuration is loaded from the data section of this module file and then merged with the configuration found at F<.hotpotato/config.ini> in the user's home directory.

=head1 METHODS

=head2 path_from_sound_theme

Loads a configured file path from the current sound theme and returns.

=head2 locate_file

Looks for a file in the resource directories for L<Games::HotPotato>. This includes the directory named after this module in the Perl library directory. The secondary location is the F<.hotpotato> directory in the user's home directory.

=head2 random_time

Generate a random time.

=head2 run

Start the timer.

=head1 SEE ALSO

L<hot-potato>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
[sounds zostay]
start_alert = zostay/start_alert.wav
rush_alert  = zostay/rush_alert.wav
final_alert = zostay/final_alert.wav
start_music = zostay/start_music.wav
rush_music  = zostay/rush_music.wav
