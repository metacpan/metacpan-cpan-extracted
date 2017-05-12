#! perl

my $id = "25-pitch";

# Change tempo with a ratio.

use strict;
use warnings;
use Test::More tests => 3;
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

# Change pitch.
$op->change_pitch({ int => -1 });

# Dump it.
$op->dump_to_file("$id.mid.dmp");

# Compare the dumps.
if ( differ("$id.mid.dmp", "$id.out.dmp", 1) ) {
    fail("compare -1");
    exit;
}
else {
    pass("compare -1");
    # Cleanup.
    unlink(@cln);
}

# Dump ref copy.
string_to_file($data, "$id.out.dmp");

# Change pitch back.
$op->change_pitch({ int => 1 });

# Dump it.
$op->dump_to_file("$id.mid.dmp");

# Compare the dumps.
if ( differ("$id.mid.dmp", "$id.out.dmp", 1) ) {
    fail("compare 1");
}
else {
    pass("compare 1");
    # Cleanup.
    unlink(@cln);
}

################################################################

INIT { $data = << 'EODEODEOD';
MIDI::Tweaks::Opus->new({
  'format' => 1,
  'ticks'  => 256,
  'tracks' => [   # 2 tracks...

    # Track #0 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 4 events.
        ['time_signature', 0, 4, 2, 24, 8],
        ['key_signature', 0, 0, 0],
        ['set_tempo', 0, 600000],
        ['text_event', 1, ''],
      ]
    }),
    
    # Track #1 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 30 events.
        ['control_change', 0, 0, 0, 0],
        ['control_change', 0, 0, 32, 0],
        ['control_change', 0, 0, 7, 100],
        ['patch_change', 0, 0, 52],
        ['lyric', 128, '1.If '],
        ['note_on', 0, 0, 70, 68],
        ['note_on', 128, 0, 70, 0],
        ['lyric', 0, 'ev'],
        ['note_on', 0, 0, 71, 75],
        ['note_on', 128, 0, 71, 0],
        ['lyric', 0, '\'ry'],
        ['note_on', 0, 0, 70, 80],
        ['note_on', 128, 0, 70, 0],
        ['lyric', 0, 'bo'],
        ['note_on', 0, 0, 73, 77],
        ['note_on', 128, 0, 73, 0],
        ['lyric', 0, 'dy '],
        ['note_on', 0, 0, 70, 75],
        ['note_on', 128, 0, 70, 0],
        ['lyric', 0, 'had '],
        ['note_on', 0, 0, 69, 76],
        ['note_on', 128, 0, 69, 0],
        ['lyric', 0, 'an '],
        ['note_on', 0, 0, 69, 78],
        ['note_on', 128, 0, 69, 0],
        ['lyric', 0, 'o'],
        ['note_on', 0, 0, 67, 67],
        ['note_on', 384, 0, 67, 0],
        ['note_on', 0, 0, 70, 68],
        ['note_on', 128, 0, 70, 0],
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
      'events' => [  # 4 events.
        ['time_signature', 0, 4, 2, 24, 8],
        ['key_signature', 0, 5, 0],
        ['set_tempo', 0, 600000],
        ['text_event', 1, ''],
      ]
    }),
    
    # Track #1 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 30 events.
        ['control_change', 0, 0, 0, 0],
        ['control_change', 0, 0, 32, 0],
        ['control_change', 0, 0, 7, 100],
        ['patch_change', 0, 0, 52],
        ['lyric', 128, '1.If '],
        ['note_on', 0, 0, 69, 68],
        ['note_on', 128, 0, 69, 0],
        ['lyric', 0, 'ev'],
        ['note_on', 0, 0, 70, 75],
        ['note_on', 128, 0, 70, 0],
        ['lyric', 0, '\'ry'],
        ['note_on', 0, 0, 69, 80],
        ['note_on', 128, 0, 69, 0],
        ['lyric', 0, 'bo'],
        ['note_on', 0, 0, 72, 77],
        ['note_on', 128, 0, 72, 0],
        ['lyric', 0, 'dy '],
        ['note_on', 0, 0, 69, 75],
        ['note_on', 128, 0, 69, 0],
        ['lyric', 0, 'had '],
        ['note_on', 0, 0, 68, 76],
        ['note_on', 128, 0, 68, 0],
        ['lyric', 0, 'an '],
        ['note_on', 0, 0, 68, 78],
        ['note_on', 128, 0, 68, 0],
        ['lyric', 0, 'o'],
        ['note_on', 0, 0, 66, 67],
        ['note_on', 384, 0, 66, 0],
        ['note_on', 0, 0, 69, 68],
        ['note_on', 128, 0, 69, 0],
      ]
    }),
    
  ]
});
EODEODEOD
}
