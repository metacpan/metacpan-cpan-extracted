#!perl
use strict;
use warnings;
use Data::Dumper;
use Test2::V0;
use MIDI;
use MIDI::Segment;

use constant { TRACK1 => 0, };

#plan 1;

# FOUR COWBELL - four equal note_on events plus some other stuff
my $opus = MIDI::Opus->new( { from_file => 't/cowbell.midi' } );
my ( $mis, $durations ) = MIDI::Segment->new($opus);
is( $durations, [ 96, 192 ] );    # quarter note or half note split

my $seqs = $mis->split(192);
# a text event and a tempo change are in the first segment, along with
# two quarter notes (the tracks are inside the segments so the segment
# list can be shuffled)
is( scalar @$seqs,                  2 );    # two half note segments
is( scalar @{ $seqs->[0][TRACK1] }, 6 );
is( scalar @{ $seqs->[1][TRACK1] }, 4 );
# are the velocities still in the right order?
my @velo = map { $_->[0] eq 'note_on' ? $_->[4] : () }
  map { @{ $_->[TRACK1] } } @$seqs;
is( \@velo, [ 127, 126, 125, 124 ] );

$seqs = $mis->split(96);
is( scalar @$seqs,                  4 );  # four quarter note segments
is( scalar @{ $seqs->[0][TRACK1] }, 4 );

like( dies { $mis->split(1) }, qr/no onset at/ );

# COWPRIME - this one cannot be equally segmented
# TODO maybe this should throw an error instead of them having to check
# whether there are any durations?
$opus = MIDI::Opus->new( { from_file => 't/cowprime.midi' } );
( $mis, $durations ) = MIDI::Segment->new($opus);
is( scalar @$durations, 0 );

# LILYPOND - control track without note_on events
$opus = MIDI::Opus->new( { from_file => 't/lilypond.midi' } );
like( dies { MIDI::Segment->new($opus) }, qr/no note_on in track/ );

# RAGGED - the tracks are different length
$opus = MIDI::Opus->new( { from_file => 't/ragged.midi' } );
like( dies { MIDI::Segment->new($opus) }, qr/problematic MIDI v=0 r=1/ );

# VAGUE - note_on with zero dtime at tail of track (does this actually
# happen in the wild, and if so does it matter for the segment
# calculation?)
$opus = MIDI::Opus->new( { from_file => 't/vague.midi' } );
like( dies { MIDI::Segment->new($opus) }, qr/problematic MIDI v=1 r=0/ );

done_testing
