# Same as round_trip.t, but uses n2s() instead of d2s().
# Also contains extra tests to check that n2s() handles
# non-NV scalars as expected.

use strict;
use warnings;
use Math::Ryu qw(:all);
use Config;

use Test::More;

END{ done_testing(); };

my $count = 0;

for (-324 .. -290, -200 .. -180, -50 .. 50, 200 .. 250) {
  for(1..10) {
    my $str = (5 + int(rand(5))) . "." . random_digits() . "e$_";

    $count ++;
    $str = '-' . $str unless $count % 5;

    my $nv = s2d($str);
    $nv /= 10 unless $count % 3;

    cmp_ok(s2d(n2s($nv)), '==', $nv, sprintf("%.17g", $nv) . ": round trip succeeds");
  }
}

my $i = ~0;
cmp_ok(n2s($i), 'eq', "$i", "$i: as expected");

eval {$count = n2s(\$i);};
like($@, qr/^/, "reference not accepted as expected");

my $s = "18446744073709551701";
cmp_ok(n2s($s), 'eq', d2s($s), "$s: as expected");

$s = "1844674407";
cmp_ok(n2s($s), 'eq', "1844674407", "$s: as expected");

sub random_digits {
    my $ret = '';
    $ret .= int(rand(10)) for 1 .. 10;
    return $ret;
}

$s = '123456789' x 10;

if($] >= 5.03 || sprintf("%.17g", $s + 0) eq '1.2345678912345679e+89') {
  cmp_ok(lc(n2s($s)), 'eq', '1.2345678912345679e89', 'n2s converts long string to 17-digit double');
}
else { warn "skipping 'n2s converts long string to 17-digit double' test as perl assigns the value incorrectly\n" }

$s = '123456789' x 2;

if($Config{ivsize} == 4) {
  if($] >= 5.03 || sprintf("%.17g", $s + 0) eq '1.2345678912345679e+89') {
    cmp_ok(lc(n2s($s)), 'eq', '1.2345678912345678e17', 'n2s converts "123456789123456789" to "1.2345678912345678e17"');
  }
  else { warn "skipping 'n2s converts \"123456789123456789\" to \"1.2345678912345678e17\"' test as perl assigns the value incorrectly\n" }
}
else {
  cmp_ok(lc(n2s($s)), 'eq', $s, 'n2s leaves "123456789123456789" unchanged');
}

