use strict;
use warnings;
use Math::MPFR;
use Config;

use Math::FakeDD qw(:all);

use Test::More;

my @subn_args = (53, -1073, 1024);

#if($Math::MPFR::VERSION < 4.44 ) {
#  cmp_ok(1, '==', 1, 'dummy test');
#  warn "Skipping tests because Math::MPFR version ($Math::MPFR::VERSION) needs to be at 4.44 or greater";
#  done_testing();
#  exit 0;
#}

if(!Math::MPFR::MPFR_4_0_2_OR_LATER) {
  cmp_ok(1, '==', 1, 'dummy test');
  warn "Skipping tests because mpfr version (", Math::MPFR::MPFR_VERSION_STRING(), ") needs to be at 4.0.2 or greater";
  done_testing();
  exit 0;
}

*_atonv = \&Math::MPFR::atonv;

my @pow = (1023 .. 1074);

# Skip these tests unless NVSIZE is 8.
# They are not properly constructed for
# perls whose NVSIZE != 8.
if($Config{nvsize} == 8) {
  for(1..500) {
    my $arg = 0;
    my $how_many = 2 + int(rand(10));

    for(1 .. $how_many) {
      $arg += 2 ** -($pow[int(rand(51))]);
    }

    if($] < 5.03) {
      # Perl's assignment to NV is not reliable - so use Math::MPFR::atonv() instead.
      cmp_ok(_atonv(Math::MPFR::nvtoa($arg)), '==', _atonv(Math::MPFR::mpfrtoa(Math::MPFR->new($arg))), "$arg - strings numify equivalently");
    }
    else {
      cmp_ok(Math::MPFR::nvtoa($arg), '==', Math::MPFR::mpfrtoa       (Math::MPFR->new($arg)), "$arg - strings numify equivalently");
    }

    cmp_ok(Math::MPFR::nvtoa($arg), 'eq', mpfrtoa_subn(Math::MPFR->new($arg), 53, -1073, 1024), "$arg - strings are identical");

  }

  for my $arg('1.08646184497422e-311', '6.32404026676796e-322') {
    if($] < 5.03) {
      # Perl's assignment to NV is not reliable - so use Math::MPFR::atonv() instead.
      cmp_ok(_atonv(Math::MPFR::nvtoa($arg)), '==', _atonv(Math::MPFR::mpfrtoa(Math::MPFR->new($arg))), "$arg - strings numify equivalently");
    }
    else {
      cmp_ok(Math::MPFR::nvtoa($arg), '==', Math::MPFR::mpfrtoa       (Math::MPFR->new($arg)), "$arg - strings numify equivalently");
    }

    cmp_ok(Math::MPFR::nvtoa($arg), 'eq', mpfrtoa_subn(Math::MPFR->new($arg), 53, -1073, 1024), "$arg - strings are identical");
  }
}

my $round = 0; # Round to nearest, ties to even,
my $dbl_max = Math::MPFR::Rmpfr_get_NV(
              Math::MPFR->new('0.11111111111111111111111111111111111111111111111111111e1024', 2), $round
              ); # 1.7976931348623157e+308;
my $norm_min = Math::MPFR::Rmpfr_get_NV( Math::MPFR->new('0.1e-1021', 2), $round ); # 2.2250738585072014e-308
my $denorm_max = $norm_min - (2 ** -1074);

cmp_ok($norm_min, '>', $denorm_max, "NORM_MIN > DENORM_MAX");

my $mpfr_inf = Math::MPFR->new($dbl_max);
Math::MPFR::Rmpfr_nextabove($mpfr_inf);
my $inf = Math::MPFR::Rmpfr_get_d($mpfr_inf, 0);

my $zero = Math::MPFR::Rmpfr_get_d(Math::MPFR->new(0), 0);
my $neg_zero = Math::MPFR::Rmpfr_get_d(Math::MPFR->new('-0.0'), 0);

#if($Config{nvsize} == 8) {
#  for my $arg($dbl_max, $norm_min, $denorm_max, $inf, $zero, -$dbl_max, -$norm_min, -$denorm_max, -$inf, $neg_zero) {
#    cmp_ok(Math::MPFR::nvtoa($arg), '==', Math::MPFR::mpfrtoa       (Math::MPFR->new($arg)), "$arg - strings numify equivalently");
#    cmp_ok(Math::MPFR::nvtoa($arg), 'eq', mpfrtoa_subn(Math::MPFR->new($arg), 53, -1073, 1024), "$arg - strings are identical");
#  }
#}

for my $arg($dbl_max, $norm_min, $denorm_max, $inf, $zero, -$dbl_max, -$norm_min, -$denorm_max, -$inf, $neg_zero) {
  cmp_ok(mpfrtoa_subn(Math::MPFR->new($arg), @subn_args), '==', Math::MPFR::mpfrtoa(Math::MPFR->new($arg)), "$arg - strings numify equivalently");
  cmp_ok(mpfrtoa_subn(Math::MPFR->new($arg), @subn_args), 'eq', mpfrtoa_subn(Math::MPFR->new($arg), 53, -1073, 1024), "$arg - strings are identical");
}

my($dd1, $dd2, $dd3, $dd4) = ( Math::FakeDD->new(2.01) ** -505, Math::FakeDD->new(2.01) ** -520,
                               Math::FakeDD->new(2.01) ** 505, Math::FakeDD->new(2.01) ** 520 );

#print "$dd1\n"; # [7.691145062557722e-154 5.891394197874965e-170]
#print "$dd2\n"; # [2.177961213729931e-158 -1.7775114692278932e-174]
#print $dd1 ** 2, "\n"; [5.915371237330603e-307 5e-324]
#print $dd2 ** 2, "\n"; [4.74351503e-316 0.0]

cmp_ok($dd1 ** 2, '==', $dd1 * $dd1,          '$dd1 ** 2 == $dd1 * $dd1');
cmp_ok($dd1 ** 2, '==', $dd1 / $dd3,          '$dd1 ** 2 == $dd1 / $dd3');

cmp_ok($dd2 ** 2, '==', $dd2 * $dd2,          '$dd2 ** 2 == $dd2 * $dd2');
cmp_ok($dd2 ** 2, '==', $dd2 / $dd4,          '$dd2 ** 2 == $dd2 / $dd4');

my $sq_subn = $dd2 ** 2;
cmp_ok($sq_subn->{lsd}, '==', 0, '$sq_subn->{lsd} is 0');

$dd1 *= $dd2;
cmp_ok($dd1->{lsd}, '==', 0, '$dd1->{lsd} has changed to 0');

$sq_subn += 2.01 ** -1041;
#print "$sq_subn\n";  [7.10347275e-316 0.0]
cmp_ok($sq_subn->{lsd}, '==', 0, '$sq_subn->{lsd} is still 0');

my $sq_subn_retrieved = $sq_subn - (2.01 ** -1041);
cmp_ok($sq_subn_retrieved, '==', $dd2 ** 2, 'Original value retrieved');

done_testing();

sub mpfrtoa_subn { # obj, prec, emin, emax
  # Pure-Perl version of Math::MPFR::mpfrtoa_subn (as introduced into Math-MMPFR-4.46).
  return Math::MPFR::mpfrtoa($_[0]) if !Math::MPFR::Rmpfr_regular_p($_[0]);

  my $exp = Math::MPFR::Rmpfr_get_exp($_[0]);

  if($exp > $_[3]) {
    return '-Inf' if Math::MPFR::Rmpfr_signbit($_[0]);
    return 'Inf';
  }

  if($exp < $_[2]) {
    return '-0.0' if Math::MPFR::Rmpfr_signbit($_[0]);
    return '0.0';
  }

  if($exp < $_[2] + $_[1] - 1) {
    # Value is subnormal.
    my $prec = $exp + 1 - $_[2];
    my $mpfr_temp = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_set($mpfr_temp, $_[0], 0);
    return Math::MPFR::_mpfrtoa($mpfr_temp, $_[1]); # Needs 2-arg form of mpfrtoa()
  }

  return Math::MPFR::_mpfrtoa($_[0], 0);
}
