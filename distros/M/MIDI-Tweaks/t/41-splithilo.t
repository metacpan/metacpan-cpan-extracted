#! perl

my $id = "41-splithilo";

# Split on H/L, using input with sinle and double notes.
# TEST: Track start / ends with a double note.

use strict;
use warnings;
use Test::More tests => 2;
use MIDI::Tweaks;
-d "t" && chdir "t";
require "./tools.pl";

my @cln = ( "$id.mid.dmp", "$id.out.dmp");

# Cleanup.
unlink(@cln);

my $data;			# filled by INIT
my $rslt;			# filed by INIT

# Dump ref copy.
string_to_file($rslt, "$id.out.dmp");

# Load from data.
my $op = eval $data;
ok($op, "load from DATA");

# Split.
my ($h, $l) = $op->tracks_r->[0]->split_hilo;

# Fill opus with new tracks.
$op->tracks($h, $l);

# Dump it.
$op->dump_to_file("$id.mid.dmp");

# Compare the dumps.
if ( differ("$id.mid.dmp", "$id.out.dmp", 1) ) {
    fail("compare");
}
else {
    pass("compare");
    # Cleanup.
    unlink(@cln);
}

################################################################

INIT { $data = << 'EODEODEOD';
MIDI::Tweaks::Opus->new({
  'format' => 1,
  'ticks'  => 256,
  'tracks' => [   # 1 tracks...

    # Track #0 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 42 events.
        ['time_signature', 0, 4, 2, 24, 8],
        ['key_signature', 0, 0, 0],
        ['set_tempo', 0, 600000],
        ['control_change', 0, 0, 0, 0],
        ['control_change', 0, 0, 32, 0],
        ['patch_change', 0, 0, 52],
        ['lyric', 128, '1.If '],
        ['note_on', 0, 0, 70, 68],
        ['note_on', 0, 0, 40, 68],
        ['note_on', 128, 0, 70, 0],
        ['note_on', 0, 0, 40, 0],
        ['lyric', 0, 'ev'],
        ['note_on', 0, 0, 71, 75],
        ['note_on', 0, 0, 55, 75],
        ['note_on', 128, 0, 71, 0],
	['note_off', 0, 0, 55, 75],
        ['lyric', 0, '\'ry'],
        ['note_on', 0, 0, 44, 80],
        ['note_on', 0, 0, 70, 80],
        ['note_on', 128, 0, 70, 0],
	['note_off', 0, 0, 44, 75],
        ['lyric', 0, 'bo'],
        ['note_on', 0, 0, 73, 77],
        ['note_on', 0, 0, 72, 77],
        ['note_on', 128, 0, 73, 0],
        ['note_on', 0, 0, 72, 0],
        ['lyric', 0, 'dy '],
        ['note_on', 0, 0, 70, 75],
        ['note_on', 128, 0, 70, 0],
        ['lyric', 0, 'had '],
        ['note_on', 0, 0, 69, 76],
        ['note_on', 128, 0, 69, 0],
        ['lyric', 0, 'an '],
        ['note_on', 0, 0, 69, 78],
        ['note_on', 0, 0, 80, 78],
        ['note_on', 128, 0, 69, 0],
        ['note_on', 0, 0, 80, 0],
        ['lyric', 0, 'o'],
        ['note_on', 0, 0, 67, 67],
        ['note_on', 0, 0, 70, 68],
        ['note_on', 384, 0, 67, 0],
        ['note_on', 0, 0, 70, 0],
      ]
    }),
    
  ]
});
EODEODEOD
}

INIT { $rslt = << 'EODEODEOD';
MIDI::Tweaks::Opus->new({
  'format' => 1,
  'ticks'  => 256,
  'tracks' => [   # 2 tracks...

    # Track #0 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 22 events.
        ['time_signature', 0, 4, 2, 24, 8],
        ['key_signature', 0, 0, 0],
        ['set_tempo', 0, 600000],
        ['control_change', 0, 0, 0, 0],
        ['control_change', 0, 0, 32, 0],
        ['patch_change', 0, 0, 52],
        ['note_on', 128, 0, 70, 68],
        ['note_on', 128, 0, 70, 0],
        ['note_on', 0, 0, 71, 75],
        ['note_on', 128, 0, 71, 0],
        ['note_on', 0, 0, 70, 80],
        ['note_on', 128, 0, 70, 0],
        ['note_on', 0, 0, 73, 77],
        ['note_on', 128, 0, 73, 0],
        ['note_on', 0, 0, 70, 75],
        ['note_on', 128, 0, 70, 0],
        ['note_on', 0, 0, 69, 76],
        ['note_on', 128, 0, 69, 0],
        ['note_on', 0, 0, 80, 78],
        ['note_on', 128, 0, 80, 0],
        ['note_on', 0, 0, 70, 68],
        ['note_on', 384, 0, 70, 0],
      ]
    }),
    
    # Track #1 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 22 events.
        ['time_signature', 0, 4, 2, 24, 8],
        ['key_signature', 0, 0, 0],
        ['set_tempo', 0, 600000],
        ['control_change', 0, 0, 0, 0],
        ['control_change', 0, 0, 32, 0],
        ['patch_change', 0, 0, 52],
        ['note_on', 128, 0, 40, 68],
        ['note_on', 128, 0, 40, 0],
        ['note_on', 0, 0, 55, 75],
        ['note_off', 128, 0, 55, 75],
        ['note_on', 0, 0, 44, 80],
        ['note_off', 128, 0, 44, 75],
        ['note_on', 0, 0, 72, 77],
        ['note_on', 128, 0, 72, 0],
        ['note_on', 0, 0, 70, 75],
        ['note_on', 128, 0, 70, 0],
        ['note_on', 0, 0, 69, 76],
        ['note_on', 128, 0, 69, 0],
        ['note_on', 0, 0, 69, 78],
        ['note_on', 128, 0, 69, 0],
        ['note_on', 0, 0, 67, 67],
        ['note_on', 384, 0, 67, 0],
      ]
    }),
    
  ]
});
EODEODEOD
}
