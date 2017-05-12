use Test;
BEGIN { plan tests => 31 }

use Games::Cards::Poker qw(:all);

ok(1);
my $shrt = HandScore(5552);
ok($shrt, 'AT944');

$shrt = HandScore(708);
ok($shrt, 'AT943s');

$shrt = HandScore(0);
ok($shrt, 'AKQJTs');

$shrt = HandScore(7459);
ok($shrt, '76532');

my $scor = ScoreHand('65542');
ok($scor, 5522);

$scor = ScoreHand('65532');
ok($scor, 5523);

$scor = ScoreHand('55432');
ok($scor, 5524);

$scor = ScoreHand('AKQ44');
ok($scor, 5525);

$scor = ScoreHand('65442');
ok($scor, 5742);

$scor = ScoreHand('64432');
ok($scor, 5743);

$scor = ScoreHand('54432');
ok($scor, 5744);

$scor = ScoreHand('AKQ33');
ok($scor, 5745);

$scor = ScoreHand('65332');
ok($scor, 5962);

$scor = ScoreHand('64332');
ok($scor, 5963);

$scor = ScoreHand('54332');
ok($scor, 5964);

$scor = ScoreHand('AKQ22');
ok($scor, 5965);

$scor = ScoreHand('65322');
ok($scor, 6182);

$scor = ScoreHand('64322');
ok($scor, 6183);

$scor = ScoreHand('54322');
ok($scor, 6184);

$scor = ScoreHand('AKQJ9');
ok($scor, 6185);

$shrt = HandScore(3);
ok($shrt, 'JT987s');

$scor = ScoreHand($shrt);
ok($scor, 3);

$shrt = HandScore(7);
ok($shrt, '76543s');

$scor = ScoreHand($shrt);
ok($scor, 7);

$shrt = HandScore(15);
ok($shrt, 'AAAA8');

$scor = ScoreHand($shrt);
ok($scor, 15);

$shrt = HandScore(31);
ok($shrt, 'KKKK4');

$scor = ScoreHand($shrt);
ok($scor, 31);

$shrt = HandScore(63);
ok($shrt, 'TTTT8');

$shrt = HandScore(7461);
ok($shrt, '75432');
