#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use MIDI::Drummer::Tiny ();
use MIDI::RtMidi::ScorePlayer ();
use MIDI::Util qw(midi_dump ticks);
use Music::Duration::Partition ();
use Pod::Usage qw(pod2usage);

my %opts = (
    drummers => 4,  # The number of drummers
    bpm      => 90, # Beats per minute
    extend   => 4,  # Number of beats to play after all drummers have entered
    measures => 4,  # Number of bars each drummer plays before the next joins
    beats    => 4,  # Number of beats that a drummer plays per phrase motif
    pool     => 'qn den en sn', # Pool of possible phrase durations
);
GetOptions( \%opts,
    'drummers=i',
    'bpm=i',
    'extend=i',
    'measures=i',
    'beats=i',
    'pool=s',
    'help|?',     # Call as --help or -?
    'man',        # Call as --man
) or pod2usage(2);
pod2usage(1) if $opts{help};
pod2usage(-exitval => 0, -verbose => 2) if $opts{man};

# Setup a drum score, etc
my $d = MIDI::Drummer::Tiny->new(
    bpm    => $opts{bpm},
    bars   => $opts{drummers} * $opts{measures},
    reverb => 15, # We're outside
);

# Collect the percussion instruments you wish to hear
my @drums = (
    # $d->mute_hi_conga, $d->cabasa, $d->maracas, $d->hi_bongo, $d->mute_triangle, # 5 QUIET ONES
    $d->low_bongo, $d->open_hi_conga, $d->low_conga, $d->short_guiro, $d->claves, $d->hi_wood_block, $d->low_wood_block, # 7
    $d->high_agogo, $d->low_agogo, $d->tambourine, $d->cowbell, $d->open_triangle, # 5
    # $d->vibraslap, $d->high_timbale, $d->low_timbale, $d->mute_cuica, $d->open_cuica, # 5
    # $d->hi_tom, $d->hi_mid_tom, $d->low_mid_tom, $d->low_tom, $d->hi_floor_tom, $d->low_floor_tom, # 6 drum kit toms
    # $d->kick, $d->snare, $d->open_hh, $d->pedal_hh, # 4 Western backbeat
);

print 'There are ', scalar(@drums), " known percussion instruments.\n";
die "Can't have more drummers ($opts{drummers}) than instruments!\n"
    if $opts{drummers} > @drums;

# Split the given space-separated string of durations into a list
my $pool = [ split /\s+/, $opts{pool} ];

# Make a phrase generator
my $generator = Music::Duration::Partition->new(
    size => $opts{beats},
    pool => $pool,
);

my %seen; # Drums that have been selected

# Get the amount of time to rest = beats * 96
my $rest = 'd' . ($opts{beats} * ticks($d->score));

# Common part() arguments
my %common = (
    options   => \%opts,
    drummer   => $d,
    generator => $generator,
    drums     => \@drums,
    seen      => \%seen,
    rest      => $rest,
    width     => length($opts{drummers}),
);

my @parts = (\&part) x $opts{drummers};

MIDI::RtMidi::ScorePlayer->new(
    score  => $d->score,
    parts  => [ \@parts ],
    common => \%common,
    sleep  => 2,
    port   => qr/fluid/i,
)->play;

sub part {
    my (%args) = @_;

    # Get an unseen drum to play
    my $drum = $args{drums}->[ int rand $args{drums}->@* ];
    while ($args{seen}->{$drum}++) {
        $drum = $args{drums}->[ int rand $args{drums}->@* ];
    }
    my $drum_name = midi_dump('notenum2percussion')->{$drum};

    my $motif = $args{generator}->motif; # Create a rhythmic phrase

    # Tell them what they've won!
    printf "%*d. %-19s: %s", $args{width}, $args{_part}, $drum_name, ddc($motif);

    # Either rest or play the motif
    my $part = sub {
        for my $n (1 .. $args{drummer}->bars + $args{options}->{extend}) {
            # If we are not up yet, then rest
            if ($n < ($args{_part} * $args{options}->{measures})) {
                $args{drummer}->rest($args{rest});
                next;
            }
            # Otherwise play a rhythmic phrase!
            for my $duration (@$motif) {
                # Get a fluctuating velocity between f and fff
                my $velocity = 'v' . (96 + int(rand 32));
                $args{drummer}->note($duration, $drum, $velocity);
            }
        }
    };

    return $part;
}

__END__

=head1 NAME

drum-circle

=head1 SYNOPSIS

  $ perl drum-circle --help # -? or --man
  $ perl drum-circle # use defaults
  $ perl drum-circle --drummers=11 --bpm=120 --extend=2 --measures=3
  $ perl drum-circle --beats=5 --pool='thn tqn ten tsn' # 5/4 triplets? YMMV
  # Then:
  $ timidity -c ~/timidity.cfg drum-circle.mid  # On *nix
  # Windows plays MIDI with the "Legacy Media Player"

=head1 DESCRIPTION

This program simulates a "drum circle", which may include friendly
hippies.

=head1 THE CODE

=head2 Setup

1. Set the number of B<drummers> to play. This is C<4> by default and
up to C<30> if all percussion instruments are uncommented in the code.

2. Set the number of B<extend> beats to play after all drummers have
joined the circle. This is C<4> by default.

3. Declare a L<MIDI::Drummer::Tiny> instance, that will be the beating
heart of the program. This uses the beats per minute (B<bpm> default
C<90>) and the number of B<measures> each drummer plays.

4. Declare the known percussion instruments. (Use the source, Luke.)

5. Instantiate a rhythmic phrase generator with the given number of
B<beats> and a B<pool> of possible durations.

6. Build the parts to play, one for each drummer.

=head2 Sync

Synchronize the parts, so that they are played simultaneously.

=head2 Play

Finally, play the score with an open MIDI driver, as described in
L<MIDI::RtMidi::FFI>.

=head2 Phrase

This is the meat of the program, utilizing all the things we have
setup. The subroutine generates a part (a C<CODE> reference), which
is added to the list of parts that are then played together.

1. Get an unseen instrument to use for a player.

2. Generate a rhythmic phrase (A.K.A. "motif").

3. Create an anonymous subroutine that either rests or plays the
motif for the number of total beats.

3.1. The resting is done depending on the drummer entry order (into
the circle). If we are not up yet, then rest.

3.2. If not resting, play the phrase continuously until the end.

3.2.1. For each hit, get a random velocity between soft (C<f>) and
loud (C<fff>). This gives the sound a bit of dynamic texture.

4. Return this anonymous subroutine to be gathered into a list of all
drummer parts.

=head1 SEE ALSO

The writeup: L<https://ology.github.io/2020/11/01/imitating-a-drum-circle/>

The Wikipedia entry: L<https://en.wikipedia.org/wiki/Drum_circle>

L<MIDI::Drummer::Tiny>

L<MIDI::RtMidi::FFI::ScorePlayer>

L<MIDI::Util>

L<Music::Duration::Partition>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2024 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
