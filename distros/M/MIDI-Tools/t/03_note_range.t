use Test;

BEGIN { plan tests => 12 };

use MIDI::Tools qw(note_range);

my @range;

ok(!defined note_range());

# invalid, should be lol
ok(!defined note_range('note_on', 0, 0, 60, 100));

ok(!defined note_range([]));

# invalid, should be lol
ok(!defined note_range([ 'note_on', 0, 0, 60, 100 ]));

ok(!defined note_range([ [] ]));

ok(!defined note_range([ [], [] ]));

ok(!defined note_range([ ['note_off', 0, 0, 60, 100] ]));

# velocity (last) is 0 => don't count, is equal to note_off
ok(!defined note_range([ ['note_on', 0, 0, 60, 0] ]));

@range = note_range([ ['note_on', 0, 0, 60, 100] ]);
ok($range[0], 60);
ok($range[1], 60);

@range = note_range([ ['text_event', 'C major chord' ],
                      ['note_on',   0, 0, 60, 100],
                      ['note_on', 120, 0, 60,   0],
                      ['note_on', 120, 0, 64, 100],
                      ['note_on', 240, 0, 64,   0],
                      ['note_on', 360, 0, 67, 100],
                      ['note_on', 360, 0, 67,   0] ]);
ok($range[0], 60);
ok($range[1], 67);

