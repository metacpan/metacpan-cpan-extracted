use Test;
BEGIN { plan tests => 7 }

use MIDI;
ok 1;

# make sure midi paradox is handled

$ifile = "t/t.mid";
$opus = MIDI::Opus->new({from_file=>$ifile});
$track = ($opus->tracks)[0];
$score_r = MIDI::Score::events_r_to_score_r($track->events_r);
MIDI::Score::dump_score( $score_r );
# ['note', 9408, 1344, 0, 69, 96],
# ['note', 9408, 1345, 0, 69, 96],
ok $score_r->[0]->[2], 1344 or die;
ok $score_r->[1]->[2], 1345 or die;
# now test the reverse (inverse midi paradox)
$events_r = MIDI::Score::score_r_to_events_r($score_r);
#note_on 9408 0 69 96
#note_on 0 0 69 96
#note_off 1344 0 69 0
#note_off 1 0 69 0
ok $events_r->[0]->[1], 9408;
ok $events_r->[1]->[1], 0;
ok $events_r->[2]->[1], 1344;
ok $events_r->[3]->[1], 1;




