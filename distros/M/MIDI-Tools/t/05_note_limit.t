use Test;

BEGIN { plan tests => 9 };

use MIDI::Tools qw(note_limit);
my $events;

# check whether everything is left as it is
$events = [ ['note_on', 0, 0, 60, 100] ];
note_limit($events, 60, 60);
ok($events->[0]->[0], 'note_on');
ok($events->[0]->[1], 0);
ok($events->[0]->[2], 0);
ok($events->[0]->[3], 60);
ok($events->[0]->[4], 100);

# note should get deleted
$events = [ ['note_on', 0, 0, 60, 100] ];
note_limit($events, 0, 0);
ok($#{$events}, -1);

$events = [ ['text_event', 'Some notes' ],
            ['note_on',   0, 0, 60, 100],
            ['note_on', 120, 0, 60,   0],
            ['note_on', 120, 0, 72, 100],
            ['note_on', 240, 0, 72,   0],
            ['note_on', 360, 0, 67, 100],
            ['note_on', 360, 0, 67,   0] ];
note_limit($events, 60, 71);
ok($#{$events}, 4);
ok($events->[2]->[3], 60);
ok($events->[3]->[3], 67);

