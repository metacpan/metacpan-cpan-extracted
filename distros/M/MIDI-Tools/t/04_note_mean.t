use Test;

BEGIN { plan tests => 12 };

use MIDI::Tools qw(note_mean);

my ($mean, $stddev);

ok(!defined note_mean());

# invalid, should be lol
ok(!defined note_mean('note_on', 0, 0, 60, 100));

ok(!defined note_mean([]));

# invalid, should be lol
ok(!defined note_mean([ 'note_on', 0, 0, 60, 100 ]));

ok(!defined note_mean([ [] ]));

ok(!defined note_mean([ [], [] ]));

ok(!defined note_mean([ ['note_off', 0, 0, 60, 100] ]));

# velocity (last) is 0 => don't count, is equal to note_off
ok(!defined note_mean([ ['note_on', 0, 0, 60, 0] ]));


($mean, $stddev) = note_mean([ ['note_on', 0, 0, 60, 100] ]);
ok($mean,   60);
ok($stddev, 0);

($mean, $stddev) = note_mean([ ['text_event', 'Whole-tone scale in C' ],
                               ['note_on',   0, 0, 60, 100],
                               ['note_on', 120, 0, 60,   0],
                               ['note_on', 120, 0, 62, 100],
                               ['note_on', 240, 0, 62,   0],
                               ['note_on', 360, 0, 64, 100],
                               ['note_on', 480, 0, 64,   0],
                               ['note_on', 480, 0, 66, 100],
                               ['note_on', 600, 0, 66,   0],
                               ['note_on', 600, 0, 68, 100],
                               ['note_on', 720, 0, 68,   0],
                               ['note_on', 720, 0, 70, 100],
                               ['note_on', 840, 0, 70,   0],
                               ['note_on', 840, 0, 72, 100],
                               ['note_on', 960, 0, 72,   0] ]);
ok($mean,   66);
ok($stddev, 4);

