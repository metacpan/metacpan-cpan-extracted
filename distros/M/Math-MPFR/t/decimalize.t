use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;
use Test::More;

# With version 4 and later of mpfr, minimum precision is 1.
# For version 3 and earlier, minimum precision is 2.
my $prec_correction = 0;
$prec_correction++ if 4 > MPFR_VERSION_MAJOR;

if(Math::MPFR::MPFR_3_1_6_OR_LATER) {

  like( decimalize(Math::MPFR->new()), '/^nan$/i',
         'NaN decimalizes as expected');

  if('inf' + 0 == 0) { # Can happen with older perls on MS Win32

    like( decimalize(Math::MPFR->new(99 ** (99 ** 99))),  '/^inf$/i',
           'Inf decimalizes as expected');

    like( decimalize(Math::MPFR->new(-(99 ** (99 ** 99)))), '/^\-inf$/i',
           '-Inf decimalizes as expected');
  }
  else {

    like( decimalize(Math::MPFR->new('inf' + 0)),  '/^inf$/i',
           'Inf decimalizes as expected');

    like( decimalize(Math::MPFR->new('-inf' + 0)), '/^\-inf$/i',
           '-Inf decimalizes as expected');
  }

  cmp_ok( decimalize(Math::MPFR->new(0)),    'eq', '0',
           '0 decimalizes as expected');

  cmp_ok( decimalize(Math::MPFR->new('-0')), 'eq', '-0',
         '-0 decimalizes as expected');

  cmp_ok( decimalize(Math::MPFR->new('0.1')),
         'eq', '0.1000000000000000055511151231257827021181583404541015625',
         '0.1 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('1.7976931348623157e+308')),
                                        Math::MPFR->new('1.7976931348623157e+308')), '==', 1,
                                        'DBL_MAX decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('-1.7976931348623157e+308')),
                                        Math::MPFR->new('-1.7976931348623157e+308')), '==', 1,
                                        '-DBL_MAX decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('1' x 51, 2)),
                                        Math::MPFR->new('1' x 51, 2)), '==', 1,
                                        '2251799813685247.0 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('-' . ('1' x 51), 2)),
                                        Math::MPFR->new('-' . ('1' x 51), 2)), '==', 1,
                                        '-2251799813685247.0 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('1' x 52, 2)),
                                        Math::MPFR->new('1' x 52, 2)), '==', 1,
                                        '4.503599627370495e15 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('-' . ('1' x 52), 2)),
                                        Math::MPFR->new('-' . ('1' x 52), 2)), '==', 1,
                                        '-4.503599627370495e15 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('1' x 53, 2)),
                                        Math::MPFR->new('1' x 53, 2)), '==', 1,
                                        '9.007199254740991e15 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('-' . ('1' x 53), 2)),
                                        Math::MPFR->new('-' . ('1' x 53), 2)), '==', 1,
                                        '-9.007199254740991e15 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('1' x 54, 2)),
                                        Math::MPFR->new('1' x 54, 2)), '==', 1,
                                        '1.8014398509481984e16 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('-' . ('1' x 54), 2)),
                                        Math::MPFR->new('-' . ('1' x 54), 2)), '==', 1,
                                        '-1.8014398509481984e16 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('1' x 55, 2)),
                                        Math::MPFR->new('1' x 55, 2)), '==', 1,
                                        '3.6028797018963968e16 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('-' . ('1' x 55), 2)),
                                        Math::MPFR->new('-' . ('1' x 55), 2)), '==', 1,
                                        '-3.6028797018963968e16 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new(('1' x 53) . '0', 2)),
                                        Math::MPFR->new(('1' x 53) . '0', 2)), '==', 1,
                                        '3.6028797018963964e16 decimalizes as expected');

  cmp_ok(check_exact_decimal(decimalize(Math::MPFR->new('-' . ('1' x 53) . '0', 2)),
                                        Math::MPFR->new('-' . ('1' x 53) . '0', 2)), '==', 1,
                                        '-3.6028797018963964e16 decimalizes as expected');

  my $rand_max = 500;
  $rand_max    = 5000
    if $Config{nvsize} > 8;

  for my $v (1 .. 1290) {

   my $exp =  $v < 900 ? int(rand(25))
                     : int(rand($rand_max));

   $exp = -$exp if $v % 3;
   my $x = 1 + int(rand(99000));
   my $z = 5 - length($x);
   my $s1 = '0.' . ('0' x $z) . "${x}e${exp}";
   my $s2 = int(rand(500)) . "." . ('0' x $z) . "${x}e${exp}";
   my $s3 = '1' . ('0' x $z) . "${x}e${exp}";

   unless($v % 5) {
     for my $string($s1, $s2, $s3) { $string = '-' . $string }
   }

   my $prec;
   $prec = $v < 10 ? $v + $prec_correction
                   : 1 + int(rand(200));
   Rmpfr_set_default_prec($prec);

   my $op1 = Math::MPFR->new($s1);
   my $op2 = Math::MPFR->new($s2);
   my $op3 = Math::MPFR->new($s3);

   my $str1 = decimalize($op1);
   my $str2 = decimalize($op2);
   my $str3 = decimalize($op3);

   cmp_ok(check_exact_decimal($str1, $op1), '==', 1, "'$s1', at precision $prec, decimalized as expected");
   cmp_ok(check_exact_decimal($str2, $op2), '==', 1, "'$s2', at precision $prec, decimalized as expected");
   cmp_ok(check_exact_decimal($str3, $op3), '==', 1, "'$s3', at precision $prec, decimalized as expected");

  }
}

else {
    warn " Unable to validate decimalize() results.\n";
    warn " check_exact_decimal() requires mpfr-3.1.6 or later.\n";
    warn " Math::MPFR was built against mpfr-", MPFR_VERSION_STRING, ".";

    eval { check_exact_decimal(decimalize(Math::MPFR->new(23.2))) };


    ok( $@ =~ m/Math::MPFR was built against mpfr\-/, '$@ set as expected' );

}

done_testing();
