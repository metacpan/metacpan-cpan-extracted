use Test;
BEGIN { plan tests => 4 }

use MIDI;

# test opus skyline

$ifile = "t/skyline.mid";
$opus = MIDI::Opus->new({from_file=>$ifile});
print "format ",$opus->format(),"\n";
print "tracks ", scalar($opus->tracks),"\n";

$opus->skyline({clip=>1});
print "format ",$opus->format(),"\n";
print "tracks ", scalar($opus->tracks),"\n";
$score_r = MIDI::Score::events_r_to_score_r(($opus->tracks)[0]->events_r);
foreach $e (@{$score_r}) {
    if ($e->[0] eq 'note') {
	$a{$e->[1]} = $e->[4];
    }
}

ok $a{0}, 52;
ok $a{960}, 76;
ok $a{2880}, 77;
ok $a{4800}, 79;


# ['note', 0, 960, 0, 52, 80],
# ['note', 960, 1919, 0, 76, 80],
# ['note', 2880, 1919, 0, 77, 80],
# ['note', 4800, 1919, 0, 79, 80],










