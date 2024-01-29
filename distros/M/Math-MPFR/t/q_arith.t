
# Test additional handling of mpq objects.
# The mpfr arithmetic functions that take mpq objects as arguments all have a destination
# variable of type mpfr object.
# This often means that the result contained in the destination variable has been rounded.
# We provide functions q_add_fr, q_sub_fr, q_mul_fr, q_div_fr that perform the same arithmetic
# operations, but place the results as an exact rational value in a (mpq object) destination
# variable.
#
# Also, Rmpfr_cmp_q($mpfr, $mpq) converts the value in $mpfr to its exact rational value, and
# compares that rational value to the rational value held in $mpq.
# We provide fr_cmp_q_rounded($mpfr, $mpq, $rnd) which instead converts $mpq to an mpfr object
# (using default precision, rounded according to $rnd), and then compares the two mpfr objects.
# Hence, Rmpfr_cmp_q() and fr_cmp_q_rounded() will often report different results for the same
# mpfr and mpq objects.
#
# We test these functions below:

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Test::More;

eval { require Math::GMPq; };

if($@) {
  plan skip_all => 'Math::GMPq not available';
  exit 0;
}

my $fr = Math::MPFR->new(0.5);
my $rop = Math::MPFR->new();
my $rop_check = Math::MPFR->new();
my $q_rop = Math::GMPq->new();
my $q_op = Math::GMPq->new('7/9');

q_add_fr   ( $q_rop, $q_op, $fr );
Rmpfr_set_q( $rop_check, $q_rop, MPFR_RNDN);
Rmpfr_add_q( $rop, $fr, $q_op, MPFR_RNDN);


cmp_ok( $q_rop, "==", Math::GMPq->new('23/18'), "q_add_fr produces expected result"    );
cmp_ok( $rop,   "!=", Math::GMPq->new('23/18'), "Rmpfr_add_q differs from q_add_fr"    );
cmp_ok( $rop,   "==", $rop_check,               "Rmpfr_add_q produces expected result" );

my $cmp = fr_cmp_q_rounded( $rop, $q_rop, MPFR_RNDN );
cmp_ok($cmp, "==", 0, "q_cmp_fr reports equality" );

q_sub_fr( $q_rop, $q_op, $fr );
Rmpfr_set_q( $rop_check, $q_rop, MPFR_RNDN );
Rmpfr_sub_q( $rop, $fr, $q_op, MPFR_RNDN );

cmp_ok( $q_rop, "==", Math::GMPq->new('5/18'),  "q_sub_fr produces expected result"    );
cmp_ok( $rop,   "!=", Math::GMPq->new('-5/18'), "Rmpfr_sub_q differs from complement of q_sub_fr" );
cmp_ok( $rop,   "==", -$rop_check,              "Rmpfr_sub_q produces expected result" );

$cmp = fr_cmp_q_rounded( $rop, $q_rop * -1, MPFR_RNDN );
cmp_ok($cmp, "==", 0, "q_cmp_fr reports equality" );

q_mul_fr   ( $q_rop, $q_op, $fr );
Rmpfr_set_q( $rop_check, $q_rop, MPFR_RNDN);
Rmpfr_mul_q( $rop, $fr, $q_op, MPFR_RNDN);


cmp_ok( $q_rop, "==", Math::GMPq->new('7/18'), "q_mul_fr produces expected result"    );
cmp_ok( $rop,   "!=", Math::GMPq->new('7/18'), "Rmpfr_mul_q differs from q_mul_fr"    );
cmp_ok( $rop,   "==", $rop_check,              "Rmpfr_mul_q produces expected result" );

$cmp = fr_cmp_q_rounded( $rop, $q_rop, MPFR_RNDN );
cmp_ok($cmp, "==", 0, "q_cmp_fr reports equality" );

q_div_fr    ( $q_rop, $q_op, $fr );
Rmpfr_set_q ( $rop_check, $q_rop, MPFR_RNDN );
Rmpfr_q_div ( $rop, $q_op, $fr, MPFR_RNDN);


cmp_ok( $q_rop, "==", Math::GMPq->new('14/9'), "q_div_fr produces expected result"    );
cmp_ok( $rop,   "!=", Math::GMPq->new('14/9'), "Rmpfr_q_div differs from q_div_fr"    );
cmp_ok( $rop,   "==", $rop_check,              "Rmpfr_q_div produces expected result" );

$cmp = fr_cmp_q_rounded( $rop, $q_rop, MPFR_RNDN );
cmp_ok($cmp, "==", 0, "q_cmp_fr reports equality" );

my $q_arg = Math::GMPq->new('1/3');
my $fr_arg = Math::MPFR->new(7);

q_add_fr($q_arg, $q_arg, $fr_arg);
cmp_ok($q_arg, '==', '22/3', "Returned Math::GMPq object can be operand in addition");

Math::GMPq::Rmpq_set_str($q_arg, '1/3', 10);

q_sub_fr($q_arg, $q_arg, $fr_arg);
cmp_ok($q_arg, '==', '-20/3', "Returned Math::GMPq object can be operand in subtraction");

Math::GMPq::Rmpq_set_str($q_arg, '1/3', 10);

q_mul_fr($q_arg, $q_arg, $fr_arg);
cmp_ok($q_arg, '==', '7/3', "Returned Math::GMPq object can be operand in multiplication");

Math::GMPq::Rmpq_set_str($q_arg, '1/3', 10);

q_div_fr($q_arg, $q_arg, $fr_arg);
cmp_ok($q_arg, '==', '1/21', "Returned Math::GMPq object can be operand in division");

done_testing();
