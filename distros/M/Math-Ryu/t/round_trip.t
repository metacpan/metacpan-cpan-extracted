use strict;
use warnings;
use Math::Ryu qw(:all);

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

    cmp_ok(s2d(d2s($nv)), '==', $nv, sprintf("%.17g", $nv) . ": round trip succeeds");
  }
}

sub random_digits {
    my $ret = '';
    $ret .= int(rand(10)) for 1 .. 10;
    return $ret;
}
