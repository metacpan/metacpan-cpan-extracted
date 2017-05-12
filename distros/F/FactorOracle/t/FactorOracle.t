
use Test::More tests => 14;
BEGIN { use_ok('FactorOracle') };

my $fo = new FactorOracle;
ok(defined $fo, 'factor oracle created');

my $str = "abbaaba";
$fo->add($str);

my $s = $fo->states;
ok($s == length($str) + 1, 'number of states correct');


# $to_state = $fo->trans_exists($from_state, $via_char)
$s = $fo->trans_exists(0, 'a');
ok($s == 1, 'initial transition exists');

$s = $fo->trans_exists(0, 'b');
ok($s == 2, '2nd transition exists');

$s = $fo->trans_exists(length($str)-1, 'a');
ok($s == length($str), 'final transition exists');


# what is the end position of the first occurence of the longest 
# repeating factor of the prefix ending at position N? (the suffix link)

$p = $fo->sl(7); # ba
ok($p == 4, 'suffix link correct: ba / 4');

$p = $fo->sl(6); # ab
ok($p == 2, 'suffix link correct: ab / 2');

$p = $fo->sl(5); # a
ok($p == 1, 'suffix link correct: a / 1');

$p = $fo->sl(4); # a
ok($p == 1, 'suffix link correct: a / 1');

$p = $fo->sl(3); # b
ok($p == 2, 'suffix link correct: b / 2');

$p = $fo->sl(2); # b
ok($p == 0, 'suffix link correct: b / 0');

$p = $fo->sl(1); # a
ok($p == 0, 'suffix link correct: a / 0');

$p = $fo->sl(0); # -
ok($p == -1, 'suffix link correct: null / -1');

