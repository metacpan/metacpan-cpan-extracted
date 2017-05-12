#! perl

my $id = "05-sanity";

# Check sanity.

use strict;
use warnings;
use Test::More tests => 3;
use MIDI::Tweaks;
-d "t" && chdir "t";
require "./tools.pl";

my @cln = map { "$id.$_.dmp" } qw(mid out);

# Cleanup.
unlink(@cln);

my $data;			# filled by INIT

my @msgs;
my @exps =
  ("Sanity check: channel 1 is controlled by tracks 2 and 3",
  );

{ local $SIG{__WARN__} = sub { push(@msgs, join("", @_)) };
  my $op = eval $data;
  # This will fail, since track 2 dups 1.
  if ( $@ =~ /^sanity check failed/i ) {
      pass("not sane");
  }
  else {
      diag($@) if $@;
      fail("not sane");
  }
}

is(scalar(@msgs), scalar(@exps), "warnings == as expected");
my $i = 1;
foreach ( @msgs ) {
    $_ = substr($_, 0, length($exps[0]));
    is($_, shift(@exps), "msg-$i");
    $i++;
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
      'events' => [  # 29 events.
        ['control_change', 0, 0, 0, 0],
        ['control_change', 0, 0, 32, 0],
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
    
    # Track #2 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 29 events.
        ['control_change', 0, 0, 0, 0],
        ['control_change', 0, 0, 32, 0],
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
    
    # Track #3 ...
    MIDI::Track->new({
      'type' => 'MTrk',
      'events' => [  # 29 events.
        ['control_change', 0, 7, 0, 0],
        ['control_change', 0, 7, 32, 0],
        ['patch_change', 0, 7, 52],
        ['lyric', 128, '1.If '],
        ['note_on', 0, 7, 70, 68],
        ['note_on', 128, 7, 70, 0],
        ['lyric', 0, 'ev'],
        ['note_on', 0, 7, 71, 75],
        ['note_on', 128, 7, 71, 0],
        ['lyric', 0, '\'ry'],
        ['note_on', 0, 7, 70, 80],
        ['note_on', 128, 7, 70, 0],
        ['lyric', 0, 'bo'],
        ['note_on', 0, 7, 73, 77],
        ['note_on', 128, 7, 73, 0],
        ['lyric', 0, 'dy '],
        ['note_on', 0, 7, 70, 75],
        ['note_on', 128, 7, 70, 0],
        ['lyric', 0, 'had '],
        ['note_on', 0, 7, 69, 76],
        ['note_on', 128, 7, 69, 0],
        ['lyric', 0, 'an '],
        ['note_on', 0, 7, 69, 78],
        ['note_on', 128, 7, 69, 0],
        ['lyric', 0, 'o'],
        ['note_on', 0, 7, 67, 67],
        ['note_on', 384, 7, 67, 0],
        ['note_on', 0, 7, 70, 68],
        ['note_on', 128, 7, 70, 0],
      ]
    }),
    
  ]
});
EODEODEOD
}
