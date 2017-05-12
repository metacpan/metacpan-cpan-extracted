# -*- perl -*-

# t/002_add.t - test Dummy::Repo::p51()

use Test::More tests => 6;

BEGIN { use_ok( 'Dummy::Repo' ); }

my ($n, $sum);

$n = 0;
$sum = p51($n);
cmp_ok($sum, '==', $n + 51, "Got expected sum:  $sum");

$n = 1;
$sum = p51($n);
cmp_ok($sum, '==', $n + 51, "Got expected sum:  $sum");

$n = +7;
$sum = p51($n);
cmp_ok($sum, '==', $n + 51, "Got expected sum:  $sum");

$n = -1;
$sum = p51($n);
cmp_ok($sum, '==', $n + 51, "Got expected sum:  $sum");

$n = -3;
$sum = p51($n);
cmp_ok($sum, '==', $n + 51, "Got expected sum:  $sum");
