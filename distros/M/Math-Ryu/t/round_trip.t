# Check that nv2s() is survives the round trip.
use strict;
use warnings;
use Config;
use Math::Ryu qw(:all);

use Test::More;

my $count = 0;

END{ done_testing(); };

my @range = (0 .. 50, 200 .. 250, 290 .. 324);
@range = (0 .. 50, 200 .. 250, 290 .. 324, 3950 .. 4050) if Math::Ryu::MAX_DEC_DIG > 17;

#######################
if(Math::Ryu::MAX_DEC_DIG == 17) {

  # We can run these tests on all perls because we use s2d() to assign the values,
  # thereby avoiding perl's buggy mis-assignments on perl versions prior to 5.30.0

  my $inf = 2 ** 1500;
  my $skip = 0;
  $skip =  1 if s2d(d2s($inf)) != $inf;
  if($skip) {
  warn "\n   Be warned: s2d() does not handle inf or nan correctly !!\n",
        "   DO NOT USE IT if non-finite values might be encountered\n";
  }

  for my $p (@range) {
    my $exp = $p;
    $exp = "-$exp" if $exp & 1;
    for my $it(1..20) {
      my $str = (5 + int(rand(5))) . "." . random_digits() . "e$exp";

      $count ++;
      $str = '-' . $str unless $count % 5;

      my $nv = s2d($str);
      next if ($skip && ($nv == $inf || $nv == -$inf));
      $nv /= 10 unless $count % 3;

      cmp_ok(s2d(d2s($nv)), '==', $nv, sprintf("%.17g", $nv) . ": round trip succeeds");
    }
  }
}

########################

if( $] >= 5.030 || $Config{nvtype} eq '__float128') {

  # Because we're using perl to assign the string (returned by nv2s) to an NV, we
  # must avoid the buggy perls prior to 5.30.0 that frequently mis-assigned those values.
  # The -Dusequadmath builds (that set $Config{nvtype} to __float128) were not subjected
  # to this bugginess.

  for my $p (@range) {
    my $exp = $p;
    $exp = "-$exp" if $exp & 1;
    for my $it(1..20) {
      my $str = (5 + int(rand(5))) . "." . random_digits() . "e$exp";

      $count ++;
      $str = '-' . $str unless $count % 5;

      my $nv = $str + 0;           # line 64
      $nv /= 10 unless $count % 3;

      cmp_ok(nv2s($nv), '==', $nv, sprintf("%.17g", $nv) . ": round trip succeeds");
    }
  }
}

sub random_digits {
    my $ret = '';
    $ret .= int(rand(10)) for 1 .. 10;
    return $ret;
}
