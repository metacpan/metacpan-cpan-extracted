use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..6\n";

my $rop = Math::MPFI->new();

my $si = Rmpfi_set_ui($rop, 2);

if($si == BOTH_ENDPOINTS_EXACT) {print "ok 1\n"}
else {
  warn "Expected 0, got $si\n";
  print "not ok 1\n";
}

if(RMPFI_BOTH_ARE_EXACT($si) && !RMPFI_BOTH_ARE_INEXACT($si) &&
   !RMPFI_LEFT_IS_INEXACT($si) && !RMPFI_RIGHT_IS_INEXACT($si)) {print "ok 2\n"}
else {print "not ok 2\n"}

$si = Rmpfi_sqrt($rop, $rop);

if($si == BOTH_ENDPOINTS_INEXACT) {print "ok 3\n"}
else {
  warn "Expected 0, got $si\n";
  print "not ok 3\n";
}

if(!RMPFI_BOTH_ARE_EXACT($si) && RMPFI_BOTH_ARE_INEXACT($si) &&
   RMPFI_LEFT_IS_INEXACT($si) && RMPFI_RIGHT_IS_INEXACT($si)) {print "ok 4\n"}
else {print "not ok 4\n"}

if(!RMPFI_BOTH_ARE_EXACT(LEFT_ENDPOINT_INEXACT) && !RMPFI_BOTH_ARE_INEXACT(LEFT_ENDPOINT_INEXACT) &&
   RMPFI_LEFT_IS_INEXACT(LEFT_ENDPOINT_INEXACT) && !RMPFI_RIGHT_IS_INEXACT(LEFT_ENDPOINT_INEXACT)) {print "ok 5\n"}
else {print "not ok 5\n"}

if(!RMPFI_BOTH_ARE_EXACT(RIGHT_ENDPOINT_INEXACT) && !RMPFI_BOTH_ARE_INEXACT(RIGHT_ENDPOINT_INEXACT) &&
   !RMPFI_LEFT_IS_INEXACT(RIGHT_ENDPOINT_INEXACT) && RMPFI_RIGHT_IS_INEXACT(RIGHT_ENDPOINT_INEXACT)) {print "ok 6\n"}
else {print "not ok 6\n"}

# Check that the &PL_sv_yes bug
# does not rear its ugly head here
# See https://github.com/sisyphus/math-decimal64/pull/1

sub hmmmm () {!0}
sub aaarh () {!1}
