use Test;

BEGIN { plan tests => 13 };

use MIDI::Tools qw(note_transpose);
my $events;

# check whether everything is left as it is
$events = [ ['note_on', 0, 0, 60, 100] ];
note_transpose($events, 0);
ok($events->[0]->[0], 'note_on');
ok($events->[0]->[1], 0);
ok($events->[0]->[2], 0);
ok($events->[0]->[3], 60);
ok($events->[0]->[4], 100);

$events = [ ['note_on', 0, 0, 60, 100] ];
note_transpose($events, 1);
ok($events->[0]->[3], 61);

$events = [ ['note_on', 0, 0, 60, 100] ];
note_transpose($events, -1);
ok($events->[0]->[3], 59);

$events = [ ['note_off', 0, 0, 60, 100] ];
note_transpose($events, 1);
ok($events->[0]->[3], 61);

$events = [ ['note_off', 0, 0, 60, 100] ];
note_transpose($events, -1);
ok($events->[0]->[3], 59);

$events = [ ['note_on', 0, 0, 60, 0] ];
note_transpose($events, 1);
ok($events->[0]->[3], 61);

$events = [ ['note_on', 0, 0, 60, 0] ];
note_transpose($events, -1);
ok($events->[0]->[3], 59);

# test borders
$events = [ ['note_on', 0, 0, 1, 100] ];
note_transpose($events, -5);
ok($events->[0]->[3], 0);

$events = [ ['note_on', 0, 0, 126, 100] ];
note_transpose($events, 5);
ok($events->[0]->[3], 127);

