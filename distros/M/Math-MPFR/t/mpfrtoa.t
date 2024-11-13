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
  ok(nvtoa_test($s1, $rop) == 15, "$_");
  ok(nvtoa_test($s2, $nv ) == 15, "$_");
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
  ok(nvtoa_test($s1, $f ) == 15, "$s");
  ok(nvtoa_test($s2, $nv) == 15, "$s");

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

    ok(nvtoa_test($dec, $f) == 15, "$s");
  }
}

done_testing;
