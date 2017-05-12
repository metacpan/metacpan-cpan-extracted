#! perl

my $id = "06-sanity";

# Check sanity.

use strict;
use warnings;
use Test::More tests => 8;
use MIDI::Tweaks;
-d "t" && chdir "t";
require "./tools.pl";

my @cln = map { "$id.$_.dmp" } qw(mid out);

# Cleanup.
unlink(@cln);

my $data;			# filled by INIT

my @msgs;
my @exps =
  ( "Sanity check: track 2 controls channels 1 and 8",
    "Sanity check: track 2 controls channels 1 and 8",
    "Sanity warning: track 2, time 896, note 69 already on",
    "Sanity warning: track 2, time 1024, note 69 not on",
    "Sanity warning: track 2, time 1536, note 71 not on",
    "Sanity check: track 2, unfinished note 70",
  );

{ local $SIG{__WARN__} = sub { push(@msgs, join("", @_)) };
  my $op = eval $data;
  # This will fail, since track 2 controls channels 1 and 8.
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
        ['note_on', 0, 7, 73, 77],	# err: chan
        ['note_on', 128, 7, 73, 0],	# err: chann
        ['lyric', 0, 'dy '],
        ['note_on', 0, 0, 70, 75],
        ['note_on', 128, 0, 70, 0],
        ['lyric', 0, 'had '],
        ['note_on', 0, 0, 69, 76],
        ['note_on', 128, 0, 69, 0],
        ['lyric', 0, 'an '],
        ['note_on', 0, 0, 69, 78],
        ['note_on', 0, 0, 69, 78],	# err: note on
        ['note_on', 128, 0, 69, 0],
        ['note_on', 0, 0, 69, 0],	# err: note off
        ['lyric', 0, 'o'],
        ['note_on', 0, 0, 67, 67],
        ['note_on', 384, 0, 67, 0],
        ['note_on', 0, 0, 70, 68],
        ['note_on', 128, 0, 71, 0],	# err: note off / unfinished
      ]
    }),
    
  ]
});
EODEODEOD
}
