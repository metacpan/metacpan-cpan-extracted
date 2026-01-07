# Check that nv2s() is survives the round trip.
use strict;
use warnings;
use Config;
use Math::Ryu qw(:all);

use Test::More;

my $count = 0;

END{ done_testing(); };

my @range = (0 .. 50, 200 .. 250, 290 .. 324);
push (@range, 3950 .. 4050) if Math::Ryu::MAX_DEC_DIG > 17;

# Assign using s2d() when perl has been built using an MS compiler
# && $Config{ccversion) < 19 && the exponent is in the subnormal range.

my $use_s2d = '';
{
  no warnings 'numeric';
  $use_s2d = 'MSVC'
    if( $^O eq 'MSWin32' && $Config{cc} eq 'cl' && $Config{ccversion} < 19 );
}

#######################
if(Math::Ryu::MAX_DEC_DIG == 17) {

  # We can run these tests on all perls because we use s2d() to assign the values,
  # thereby avoiding perl's buggy mis-assignments on perl versions prior to 5.30.0

  my $inf = 2 ** 1500;
  my $skip = 0;
  $skip =  1 if s2d(d2s($inf)) != $inf;
  if($skip) {
    # s2d() has now been amended and this warning should no longer appear
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
else {
  warn "\n   Skipping tests that were written exclusively for nvtype of 'double'\n";
}

########################

if( $] >= 5.030 || $Config{nvtype} eq '__float128' || $Config{nvtype} eq 'double') {

  # Because we're using perl to assign the string (returned by nv2s) to an NV, we
  # must avoid the buggy perls prior to 5.30.0 that frequently mis-assigned those values.
  # The -Dusequadmath builds (that set $Config{nvtype} to __float128) were not subjected
  # to this bugginess.
  # And we will assign using s2d() on perls whose nvtype is 'double'.

  $use_s2d = 'ALL' if( $] < 5.030 && $Config{nvtype} eq 'double');

  warn "Assigning all (double precision) values using Math::Ryu::s2d() as perl is unreliable\n"
    if($use_s2d eq 'ALL' );

  warn "Assigning (double precision) subnormal values using Math::Ryu::s2d() as perl is unreliable\n"
    if $use_s2d eq 'MSVC';


  my $format = '%.' . Math::Ryu::MAX_DEC_DIG . 'g';

  for my $p (@range) {
    my $nv;
    my $exp = $p;
    $exp = "-$exp" if $exp & 1;
    for my $it(1..20) {
      my $str = (5 + int(rand(5))) . "." . random_digits() . "e$exp";

      $count ++;
      $str = '-' . $str unless $count % 5;

      if($use_s2d eq 'ALL' && $Config{nvtype} eq 'double') { $nv = s2d($str) }
      elsif($use_s2d eq 'MSVC' && $exp < -305) { $nv = s2d($str) } # $Config{nvtype} must be 'double'
      else { $nv = $str + 0 }

      $nv /= 10 unless $count % 3;

      if( $use_s2d eq 'ALL' || ($use_s2d eq 'MSVC' && $exp < -305) ) {
        cmp_ok(s2d(nv2s($nv)), '==', $nv, sprintf("$format", $nv) . ": round trip succeeds");
      }
      else {
        cmp_ok(nv2s($nv), '==', $nv, sprintf("$format", $nv) . ": round trip succeeds");
      }
    }
  }
}
else {
  warn "\n   Skipping tests that assume that perl assigns values correctly.\n",
        "   This perl doesn't always do that\n";
  # Run a least one test.
  cmp_ok(1, '==', 1, "dummy test");
}

sub random_digits {
    my $ret = '';
    $ret .= int(rand(10)) for 1 .. 10;
    return $ret;
}

__END__


