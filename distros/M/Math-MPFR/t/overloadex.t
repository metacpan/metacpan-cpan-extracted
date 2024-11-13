# log_2() and log_10() are implementations of log2() and log10() that, just
# like the overloaded log() function, calculate their return value according
# to default precision and default rounding mode.
#
# sind() and cosd() work just like the overloaded sin() and cos() functions
# except that their argument is expressed in degrees, not radians.
#
# tangent() works just as you would expect the overloaded tan function to
# work if such overloading was available. That is, the argument is in
# radians and the return value is calculated to default precision using
# default rounding mode.
#
# tand() works just like tangent(), except that the given argument is in
# degrees.


use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

my $input_prec = 128;
my $input = Rmpfr_init2($input_prec);
my $check = Math::MPFR->new();

Rmpfr_set_ui($input, 45, MPFR_RNDN);

Rmpfr_log2($check, $input, MPFR_RNDN);
my $log_2 = log_2($input);
cmp_ok($log_2, '==', $check, "log_2() ok");
cmp_ok(Rmpfr_get_prec($log_2), '==', 53, "log_2() prec ok");

Rmpfr_log10($check, $input, MPFR_RNDN);
my $log_10 = log_10($input);
cmp_ok($log_10, '==', $check, "log_10() ok");
cmp_ok(Rmpfr_get_prec($log_10), '==', 53, "log_10() prec ok");

if(Math::MPFR::MPFR_VERSION >= 262656) {
  my $sind = sind($input);
  cmp_ok($sind, '==', Math::MPFR->new(2) ** -0.5, "sind() ok");
  cmp_ok(Rmpfr_get_prec($sind), '==', 53, "sind() prec ok");
}
else {
  eval{my $sind = sind($input);};
  like($@, qr/sind function requires mpfr\-4\.2\.0/, "sind function not available");
}

if(Math::MPFR::MPFR_VERSION >= 262656) {
   my $cosd = cosd($input);
   cmp_ok($cosd, '==', Math::MPFR->new(2) ** -0.5, "cosd() ok");
   cmp_ok(Rmpfr_get_prec($cosd), '==', 53, "cosd() prec ok");
}
else {
  eval{my $cosd = cosd($input);};
  like($@, qr/cosd function requires mpfr\-4\.2\.0/, "cosd function not available");
}


if(Math::MPFR::MPFR_VERSION >= 262656) {
  my $tand = tand($input);
  cmp_ok($tand, '==', 1, "tand() ok");
  cmp_ok(Rmpfr_get_prec($tand), '==', 53, "tand() prec ok");

  for(1 .. 10) {
    my $v = rand(360);
    cmp_ok(abs(sind(Math::MPFR->new("$v"))), '==', abs(sind(Math::MPFR->new("-$v"))), "abs(sind($v) == abs(sind(-$v)");
    cmp_ok(abs(cosd(Math::MPFR->new("$v"))), '==', abs(cosd(Math::MPFR->new("-$v"))), "abs(cosd($v) == abs(cosd(-$v)");
    cmp_ok(abs(tand(Math::MPFR->new("$v"))), '==', abs(tand(Math::MPFR->new("-$v"))), "abs(tand($v) == abs(tand(-$v)");
  }

  # Next 3 tests should pass because "380.75" and "20.75" are exactly representable in base 2 and differ by
  # exactly 360.0.
  cmp_ok(sind(Math::MPFR->new('380.75')), '==', sind(Math::MPFR->new('20.75')), 'sind(380.75) == sind(20.75)');
  cmp_ok(cosd(Math::MPFR->new('380.75')), '==', cosd(Math::MPFR->new('20.75')), 'cosd(380.75) == cosd(20.75)');
  cmp_ok(tand(Math::MPFR->new('380.75')), '==', tand(Math::MPFR->new('20.75')), 'tand(380.75) == tand(20.75)');

  # The next 3 tests should pass because "404.8" & "44.8" are NOT exactly representable in base 2 and
  # (more to the point) 404.8 - 44.8 is not sufficiently close to 360.0 as to allow the respective
  # sind()/cosd()/tand() calculations to provide identical results.
  my $big = '404.8';
  my $small = '44.8';
  cmp_ok(sind(Math::MPFR->new($big)), '!=', sind(Math::MPFR->new($small)), "sind($big) != sind($small)");
  cmp_ok(cosd(Math::MPFR->new($big)), '!=', cosd(Math::MPFR->new($small)), "cosd($big) != cosd($small)");
  cmp_ok(tand(Math::MPFR->new($big)), '!=', tand(Math::MPFR->new($small)), "tand($big) != tand($small)");

}
else {
  eval{my $tand = tand($input);};
  like($@, qr/tand function requires mpfr\-4\.2\.0/, "tand function not available");
}

my $pi = Math::MPFR->new();
Rmpfr_const_pi($pi, MPFR_RNDN);

Rmpfr_tan($check, $pi / 2, MPFR_RNDN);
my $tan = tangent($pi / 2);
cmp_ok($tan, '==', $check, "tangent() ok");
cmp_ok(Rmpfr_get_prec($tan), '==', 53, "tangent() prec ok");

done_testing();


