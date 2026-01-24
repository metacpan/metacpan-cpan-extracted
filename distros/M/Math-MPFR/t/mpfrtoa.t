# Testing mpfrtoa and mpfrtoa_subn
use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Test::More;

if( MPFR_VERSION_MAJOR() < 4) {
  warn " Skipping - these tests require mpfr-4.0.0\n or later, but we have only mpfr-",
       MPFR_VERSION_STRING(), "\n";
 ok('1' eq '1', "dummy test");
  done_testing();
  exit 0;
}

my @in = ('15400000000000000.0', '1.54e+16', '1107610000000000000.0', '1.10761e+18',
          '13687000000000000.0', '1.3687e+16', '16800000000000000000.0','1.68e+19',
          '11443200000000000000000000000.0', '1.14432e+28',
          '0.0', '-0.0', 'NaN', '-NaN', 'Inf', '-Inf', '0.1', '0.3',
           nvtoa(atonv('1.4') / 10));

Rmpfr_set_default_prec($Math::MPFR::NV_properties{bits});


if( $Math::MPFR::NV_properties{bits} == 2098 ) {
  warn "Skipping tests that are not written for DoubleDouble nvtype. (TODO.)\n"
}
else {
  push @in, ('128702000000000000000000000000000.0', '1.28702e+32');
}

for(@in) {
  my $rop = Math::MPFR->new($_);
  my $nv = Rmpfr_get_NV($rop, MPFR_RNDN);

  my $s1 = mpfrtoa($rop);
  my $s2 = nvtoa(atonv($_));

  cmp_ok($s1, 'eq', $s2, "mpfrtoa() and nvtoa() agree for $_");
  ok(dragon_test( $rop) == 15, "$_ passes dragontest (MPFR)"); # $s1
  ok(dragon_test( $nv ) == 15, "$_ passes dragon test (NV)");   # $s2
}

##############################################################################
# Check that mpfrtoa(Math::MPFR::object) eq nvtoa(NV) eq Math::Ryu::nv2s(NV) #
# whenever:                                                                  #
# a) the value of the Math::MPFR object and the NV are identical             #
# &&                                                                         #
# b) the precision of the Math::MPFR object matches the precision of the NV. #
# Math::MPFR precision has already been set such that b) is satisfied.       #
# The Math::Ryu::nv2s() check is dependent upon Math::Ryu being available.   #
##############################################################################

my $have_ryu = 0;
eval{require Math::Ryu;};
$have_ryu = 1 if(!$@ && $Math::Ryu::VERSION >= 1.05);

for(1 .. 100) {
  if($Math::MPFR::NV_properties{bits} == 2098) {
    warn "Skipping additional tests also inapplicable to DoubleDouble nvtype. (TODO.)\n";
    last;
  }

  my($e, $n, $digits, $s);

  $e = int(rand(256));
  $digits = int(Rmpfr_get_default_prec() * 0.3);
  $n .= int(rand(10)) for 1..$digits;
  $e *= -1 if $_ % 3;
  $s = "1.${n}e${e}";

  if($_ & 1) {
    $s = '-' . $s;
  }
  my $f = Math::MPFR->new($s);

  my $nv = Rmpfr_get_NV($f, MPFR_RNDN);
  my $s1 = mpfrtoa($f);
  my $s2 = nvtoa($nv);

  cmp_ok($s1, 'eq', $s2, "mpfrtoa() and nvtoa() agree for $s");
  ok(dragon_test( $f ) == 15, "$s passes dragon test (MPFR)"); # $s1
  ok(dragon_test( $nv) == 15, "$s passes dragon test (NV)");   # $s2

  if($have_ryu) {
    my $s3 = Math::Ryu::nv2s($nv);
    cmp_ok($s1, 'eq', $s3, "mpfrtoa() and Math::Ryu agree for $s");
  }
}

###########################################################################
# Next we test that, for various values at various precisions (that don't #
# match any NV precisions), the result provided by mpfrtoa() is correct.  #
###########################################################################

for my $prec( 20000, 2000, 200, 96, 21, 5 ) {
  Rmpfr_set_default_prec( $prec );
  for( 1 .. 100, '0.1', '0.10000000000000001', '0.3', nvtoa(1.4 / 10) ) {

    my($e, $n, $digits, $s);

    unless( $_ =~ /\./ ) {
      $e = int(rand(2048));
      $digits = int( Rmpfr_get_default_prec() / 5 );
      $n .= int(rand( 10 )) for 1..$digits;
      $e *= -1 if $_ % 3;
      $s = "1${n}e${e}";
    }
    else {$s = "$_"}

    my $sign = 0;
    if( $_ & 1 ) {
      $s = '-' . $s;
      $sign = 1;
    }

    my $f = Math::MPFR->new( $s );
    my $dec = mpfrtoa( $f );

    ok(dragon_test($f) == 15, "$s passes dragon test (NV)");
  }
}

{
  ### TESTING mpfrtoa_subn ###

  my($bits, $emin, $emax) = ($Math::MPFR::NV_properties{bits}, $Math::MPFR::NV_properties{emin},
                           $Math::MPFR::NV_properties{emax});

  my @args = ($bits, $emin, $emax);

  my $denorm_min = 2 ** $Math::MPFR::NV_properties{min_pow};
  my $normal_min = $Math::MPFR::NV_properties{normal_min};
  my $denorm_max = $normal_min - $denorm_min;
  my $nv_max = $Math::MPFR::NV_properties{NV_MAX};

  my $obj = Rmpfr_init2($bits);

  cmp_ok($Math::MPFR::NV_properties{min_pow} + 1, '==', $Math::MPFR::NV_properties{emin}, "min_pow + 1 == $emin");

  $denorm_min *= 2 if(!Math::MPFR::MPFR_4_0_2_OR_LATER); # Earlier versions don't properly accommodate
                                                         # an mpfr precision of 1 bit.

  for my $nv( $denorm_min,  $denorm_min * 9,  $denorm_min * 19,  $denorm_min * 1e300,  $normal_min,  $denorm_max,  $nv_max,  $nv_max * 2
             -$denorm_min, -$denorm_min * 9, -$denorm_min * 19, -$denorm_min * 1e300, -$normal_min, -$denorm_max, -$nv_max, -$nv_max * 2 ) {
    Rmpfr_set_NV($obj, $nv, MPFR_RNDN);
    cmp_ok(mpfrtoa_subn($obj, @args), 'eq', nvtoa($nv), "$nv: nvtoa and mpfrtoa_subn agree");
  }

  like(mpfrtoa_subn(Math::MPFR->new(2) ** $emax, @args), qr/^inf$/i, "mpfrtoa_subn(2 ** $emax) =~ /^inf\$/i");
  like(mpfrtoa_subn(-(Math::MPFR->new(2) ** $emax), @args), qr/^\-inf$/i, "mpfrtoa_subn(2 ** $emax) =~ /^\-inf\$/i");

  cmp_ok(mpfrtoa_subn(Math::MPFR->new(2) ** ($emin - 2), @args),   'eq',  '0.0', "mpfrtoa_subn(2 ** ($emin - 2)) eq  '0.0'");
  cmp_ok(mpfrtoa_subn(-(Math::MPFR->new(2) ** ($emin -2)), @args), 'eq', '-0.0', "mpfrtoa_subn(2 ** ($emin - 2)) eq '-0.0'");

  my $first  = 2 ** ($emin + 5);
  my $second = 2 ** ($emin + 4);
  my $third  = 2 ** ($emin + 3);
  my $fourth = 2 ** ($emin + 2);
  my $fifth  = 2 ** ($emin + 1);
  my $sixth  = 2 ** $emin;

  my @sums = ($first, $second, $third, $fourth, $fifth, $sixth,
              $first + $sixth, $first + $fifth, $first + $fourth, $first + $third, $first + $second,
              $first + $sixth + $fifth, $first + $fifth + $fourth, $first + $fourth + $third, $first + $third + $second,
              $first + $sixth + $fifth + $fourth, $first + $fifth + $fourth + $third, $first + $fourth + $third + $second,
              $first + $sixth + $fifth + $fourth + $third, $first + $fifth + $fourth + $third + $second,
              $first + $sixth + $fifth + $fourth + $third + $second);

  for(1 .. 1000) {
    my $s = rand($emin * -1) + 1.01;
    my $e = rand($emin * -1) + 1.01;
    #$e += 0.7328569; # $nv needs to be an NV, not an IV.
    $e = -$e if $_ & 1;
    my $nv = $s * (2 ** $e);
    push @sums, $nv;
  }

  # For the following values, on perl's whose nvsize && ivsize is 8, Math::Ryu's pany and spanyf
  # functions will disagree with Math::Ryu's nv2s. This is as expected.
  # For example, nv2s(6.88626464539243e+16) produces the more succinct float 6.88626464539243e+16
  # But pany(6.88626464539243e+16) and spanyf(6.88626464539243e+16) produce the integer 68862646453924328.

  push @sums, 6.88626464539243e+16, 1.49396927900039e+18, 6.8423792978218e+18,
              1.18210319200906e+18, 3.32018713959247e+18, 6.02326426473863e+17,
              4.13155289244474e+17;


  my $t = Rmpfr_init2($bits);

  my $have_ryu = 0;
  eval {require Math::Ryu;};
  if(!$@) {
    $have_ryu = 1 if $Math::Ryu::VERSION >= 1.03;
  }

  for my $sum(@sums) {
    Rmpfr_set_NV($t, $sum, MPFR_RNDN);
    my $mpfrtoa_res = mpfrtoa_subn($t, $bits, $emin, $emax);

    if($have_ryu) {
      my $ryu_res = Math::Ryu::nv2s($sum);
      cmp_ok(lc($mpfrtoa_res), 'eq', lc($ryu_res), "$sum representation agrees with Math::Ryu::nv2s()");
    }
    cmp_ok($mpfrtoa_res, 'eq', nvtoa($sum), "$sum representation agrees with Math::MPFR::nvtoa()");
  }
}

done_testing;

