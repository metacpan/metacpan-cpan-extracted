use Test;
BEGIN { plan tests => 2 }

use MIDI;
ok 1;

# test score quantize

$ifile = "t/dr_m.mid";
$opus = MIDI::Opus->new({from_file=>$ifile});

$opus->quantize({grid=>25,durations=>1});
$score_r = MIDI::Score::events_r_to_score_r(($opus->tracks)[0]->events_r);
$ticks = MIDI::Score::score_r_time($score_r);
MIDI::Score::dump_score($score_r);
ok $ticks,5950;









