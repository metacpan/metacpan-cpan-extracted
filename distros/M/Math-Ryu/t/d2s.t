# Check that d2s() is working as expected.
use strict;
use warnings;
use Config;
use Math::Ryu qw(:all);

use Test::More;

END{ done_testing(); };

if($Config{nvsize} != 8) {
  eval {d2s(3.5);};
  like($@, qr/is available only/, "d2s() not available");
  exit 0;
}


my $count = 0;

for (-324 .. -290, -200 .. -180, -50 .. 50, 200 .. 250) {
  for(1..10) {
    my $str = (5 + int(rand(5))) . "." . random_digits() . "e$_";

    $count ++;
    $str = '-' . $str unless $count % 5;

    my $nv = s2d($str);
    $nv /= 10 unless $count % 3;

    cmp_ok(s2d(d2s($nv)), '==', $nv, sprintf("%.17g", $nv) . ": round trip succeeds");
  }
}

my $pinf;

if(ryu_lln( 'inf' )) {
  $pinf = s2d('  inf  ');
  cmp_ok($pinf / $pinf, '!=', $pinf / $pinf, "inf/inf is nan");
}

if(ryu_lln( '-inf' )) {
  my $ninf = s2d('  -inf  ');
  cmp_ok($ninf, '==', -$pinf, "-inf is minus infinity");
}

if(ryu_lln( 'nan' )) {
  my $pnan = s2d('  nan  ');
  cmp_ok($pnan, '!=', $pnan, "nan != nan");
}

if(ryu_lln( '-nan' )) {
  my $nnan = s2d('  -nan  ');
  cmp_ok($nnan, '!=', $nnan, "-nan != -nan");
}

# Also check that s2d() croaks as expected if ryu_lln($arg) returns false.

eval {s2d('1.3x');};
like($@, qr/^Strings passed to s2d\(\)/, "s2d() rejects strings that don't \"look like a number\"");

eval {s2d('infi');};
like($@, qr/^Strings passed to s2d\(\)/, "s2d() rejects strings that don't \"look like a number\"");

sub random_digits {
    my $ret = '';
    $ret .= int(rand(10)) for 1 .. 10;
    return $ret;
}
