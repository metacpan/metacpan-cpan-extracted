#!/usr/bin/env perl
use strict;
use warnings;

# Successfully tested with fluidsynth, only.

# Examples:
# perl eg/dat/gol.pl 5
# perl eg/dat/gol.pl 5 eg/dat/gol-5-4x.dat
# perl eg/dat/gol.pl 5 eg/dat/gol-5-13x.dat
# perl eg/dat/gol.pl 12
# perl eg/dat/gol.pl 12 eg/dat/gol-12-blink.dat
# perl eg/dat/gol.pl 12 eg/dat/gol-5-4x.dat
# perl eg/dat/gol.pl 12 1 # render glider
# perl eg/dat/gol.pl 5 2  # render toad
# perl eg/dat/gol.pl 7 3  # render beacon
# perl eg/dat/gol.pl 12 4 # render spacship

use Game::Life::Faster ();
use Array::Transpose qw(transpose);
use MIDI::RtMidi::ScorePlayer ();
use MIDI::Util qw(setup_score set_chan_patch);
use Music::Scales qw(get_scale_MIDI);
use Storable qw(retrieve store);
use Term::ANSIScreen qw(cls);

END {
    my $score = setup_score(lead_in => 0);
    sub cleanup { return sub { $score->r('wn') } };
    MIDI::RtMidi::ScorePlayer->new(
      score    => $score,
      parts    => [ \&cleanup ],
      sleep    => 0,
      infinite => 0,
    )->play;
}

my $size = shift || 12;
my $init = shift || 0; # or some/gol-state.dat file

die "Can't have a size greater than 12 (music notes)\n"
    if $size > 12;

my $scale = 'chromatic';
if ($size == 7) {
    $scale = 'major';
}
elsif ($size == 6) {
    $scale = 'wholetone';
}
elsif ($size == 5) {
    $scale = 'pentatonic';
}

my $game = Game::Life::Faster->new($size);

my ($matrix, $x, $y);
if ($init =~ /^\d\d?$/ && $init != '0') {
    my %cells = (
        1 => [ [qw(1 1 1)],     # glider
               [qw(1 0 0)],
               [qw(0 1 0)] ],
        2 => [ [qw(0 0 0 0)],   # toad
               [qw(0 1 1 1)],
               [qw(1 1 1 0)],
               [qw(0 0 0 0)] ],
        3 => [ [qw(1 1 0 0)],   # beacon
               [qw(1 1 0 0)],
               [qw(0 0 1 1)],
               [qw(0 0 1 1)] ],
        4 => [ [qw(1 0 0 1 0)], # spaceship
               [qw(0 0 0 0 1)],
               [qw(1 0 0 0 1)],
               [qw(0 1 1 1 1)],
               [qw(0 0 0 0 0)] ],
    );
    $matrix = $cells{$init};
    $matrix = transpose($matrix) if int rand 2;
    ($x, $y) = (int rand($size - @$matrix + 1), int rand($size - @$matrix + 1));
    $game->place_points($y, $x, $matrix);
}
else {
    if ($init && -e $init) {
        $matrix = retrieve($init);
        $game->place_points(0, 0, $matrix);
    }
    else {
        die "Can't load $init\n" if $init;
        $matrix = [ map { [ map { int(rand 2) } 1 .. $size ] } 1 .. $size ];
        store($matrix, 'gol-state.dat');
        $game->place_points(0, 0, $matrix);
    }
}

my @parts = (\&part) x $size;

while (1) {
    cls();
    my @grid = $game->get_text_grid;
    my $grid = $game->get_text_grid;

    my $score = setup_score(lead_in => 0);
    my %common = (score => $score, grid => \@grid, size => $size, seen => {}, scale => $scale);

    print scalar $grid, "\n";

    MIDI::RtMidi::ScorePlayer->new(
      score    => $score,
      parts    => \@parts,
      common   => \%common,
      sleep    => 0,
      infinite => 0,
    )->play;

    $game->process;

    last unless $game->get_used_text_grid;
}

sub part {
    my (%args) = @_;

    my $track = $args{size} - $args{_part}; # bottom -> up
    my $channel = $args{_part} < 9 ? $args{_part} : $args{_part} + 1;
    my $octave = (($args{_part} - 1) % 5) + 2;
    my $patch = 4; #int rand 20;
    my @scale = (
        get_scale_MIDI('C', $octave, $args{scale}),
    );
    my @row = split //, $args{grid}->[$track];

    my $part = sub {
        set_chan_patch($args{score}, $channel, $patch);

        my @pitches;
        for my $i (0 .. $args{size} - 1) {
            if ($row[$i] eq 'X') {
                my $pitch = $scale[$i];
                push @pitches, $pitch
                    unless $args{seen}->{$pitch}++;
            }
        }
        if (@pitches) {
            $args{score}->n('qn', @pitches);
        }
    };

    return $part;
}
