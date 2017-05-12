use Test;

BEGIN { plan tests => 10 };

use MIDI::Tools qw(note_count);

ok(note_count(), 0);

# invalid, should be lol
ok(note_count('note_on', 0, 0, 60, 100), 0);

ok(note_count([]), 0);

# invalid, should be lol
ok(note_count([ 'note_on', 0, 0, 60, 100 ]), 0);

ok(note_count([ [] ]), 0);

ok(note_count([ [], [] ]), 0);

ok(note_count([ ['note_off', 0, 0, 60, 100] ]), 0);

# velocity (last) is 0 => don't count, is equal to note_off
ok(note_count([ ['note_on', 0, 0, 60, 0] ]), 0);

ok(note_count([ ['note_on', 0, 0, 60, 100] ]), 1);

ok(note_count([ ['text_event', 'C major chord' ],
                ['note_on',   0, 0, 60, 100],
                ['note_on', 120, 0, 60,   0],
                ['note_on', 120, 0, 64, 100],
                ['note_on', 240, 0, 64,   0],
                ['note_on', 360, 0, 67, 100],
                ['note_on', 360, 0, 67,   0] ]), 3);

