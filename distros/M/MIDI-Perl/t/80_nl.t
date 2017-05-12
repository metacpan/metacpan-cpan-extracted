use Test;
BEGIN { plan tests => 2 }

use MIDI;
ok 1;

# make sure events_r_to_score_r doesn't change event times

$ifile = "t/hb.mid";
$opus = MIDI::Opus->new({from_file=>$ifile});
$track = ($opus->tracks)[0];
$score_r = MIDI::Score::events_r_to_score_r($track->events_r);
$score_r = MIDI::Score::events_r_to_score_r($track->events_r);
$score_r = MIDI::Score::events_r_to_score_r($track->events_r);
#print MIDI::Score::score_r_time( $score_r );
ok MIDI::Score::score_r_time( $score_r ), 19200 or die;

 
