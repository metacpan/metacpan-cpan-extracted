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
  my $nv = Rmpfr_get_NV(Math::MPFR->new($_), MPFR_RNDN);

  my $s1 = mpfrtoa(Math::MPFR->new($_));
  my $s2 = nvtoa(atonv($_));

  cmp_ok($s1, 'eq', $s2, "mpfrtoa() and nvtoa() agree for $_");
}

##############################################################################
# First check that mpfrtoa(Math::MPFR::object) eq nvtoa(NV) whenever:        #
# a) the value of the Math::MPFR object and the NV are identical             #
# &&                                                                         #
# b) the precision of the Math::MPFR object matches the precision of the NV. #
#                                                                            #
# (Math::MPFR precision has already been set such that b) is satisfied.)     #
##############################################################################

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

    # check that $dec is not zero, or inf, or nan.

    cmp_ok( Rmpfr_regular_p( Math::MPFR->new($dec) ), '!=', 0,"First mpfrtoa() sanity check for $s" );

    # check that, having removed any leading '-' sign, the
    # length of the significand of $dec is greater than 0.

    my @str = split /e/i, $dec;

    if( $str[0] =~ /^\-/ ) {
      cmp_ok(length($str[0]), '>', 1, "Second mpfrtoa() sanity check for $s");
    }
    else {
      cmp_ok(length($str[0]), '>', 0, "Second mpfrtoa() sanity check for $s");
    }

    $str[1] = '0' unless defined $str[1];

    my $check_str = $str[0] . 'e' . $str[1];

    cmp_ok(Math::MPFR->new($s), '==', Math::MPFR->new($dec), "$dec equates to $s");

    my $dec2f = Math::MPFR->new($dec);

    cmp_ok($dec2f, '==', $f, "$dec == $f");

    ###############################################################
    # Next, check that reducing the number of significant decimal #
    # digits of $str[0] makes a difference to the assigned value. #
    ###############################################################

    my $sig = $str[0];
    my $exponent = $str[1];

    unlike( $sig, qr/\.$/, 'significand does not terminate with "."' );

    if( $sig =~ s/\.0$// ) { # if $sig ends in '.0' remove the '.0'
      while( $sig =~ /0$/ ) {
        # Here we remove all trailing zeroes as they are not siginificant digits.
        # When we remove a trailing zero, the value of the significand is
        # divided by 10 - for which we compensate by incrementing the exponent.
        chop $sig;
        $exponent++;
      }
      # Now we get to remove the least significant digit and increment the exponent.
      chop $sig;
      $exponent++
    }
    else {
      chop $sig;
      if( $sig =~ /\.$/ ) { $sig .= '0' }  # The chop() might have created the condition.
      elsif( $sig !~ /\./) { $exponent++ } # decimal point was effectively moved one place to the left.
    }

    my $in = $sig . 'e' . $exponent;
    if( $sign ) { cmp_ok(Math::MPFR->new($in), '>', $dec2f, "$in > $dec for $s ($str[0] $str[1] $prec)") }
    else { cmp_ok(Math::MPFR->new($in), '<', $dec2f, "$in < $dec for $s ($str[0] $str[1] $prec)") }

  }
}

done_testing;
