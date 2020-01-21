use strict;
use warnings;
use Test::More tests => 37;
use Math::MPFR qw(:mpfr);

# The relationship between mpfr_inter_prec() and mpfr_max_orig_len() that
# is present in the first 24 tests, does not always hold true. See tests
# 25..36 for example.
# However, that relationship should always hold true if $in[0] >= $in[2]
# (ie if old base >= new base), as tested in test 37.


my @in = (2, 53, 10, 17);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 1');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 2');

@in = (10, 15, 2, 51);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 3');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 4');

@in = (10, 16, 2, 55);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 5');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 6');

@in = (2, 56, 16, 14);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 7');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 8');

@in = (32, 1, 16, 2);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 9');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 10');

@in = (32, 2, 16, 3);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 11');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 12');


@in = (32, 4, 16, 5);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 13');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 14');

@in = (32, 5, 16, 7);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 15');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 16');

@in = (8, 15, 10, 15);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 17');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 18');

@in = (8, 16, 10, 16);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 19');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 20');

@in = (10, 15, 2, 51);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 21');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 22');

@in = (8, 21, 10, 20);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 23');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', $in[1], 'test 24');

@in = (2, 80, 10, 26);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 25');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '!=', $in[1], 'test 26'); # $in[1] == 80
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', 83,     'test 27');

@in = (8, 20, 10, 20);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 28');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '!=', $in[1], 'test 29'); # $in[1] == 20
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', 21,     'test 30');

@in = (8, 14, 32, 9);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 31');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '!=', $in[1], 'test 32'); # $in[1] == 14
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', 15,     'test 33');

@in = (2, 19, 16, 5);

cmp_ok(mpfr_min_inter_prec($in[0], $in[1], $in[2]), '==', $in[3], 'test 34');
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '!=', $in[1], 'test 35'); # $in[1] == 19
cmp_ok(mpfr_max_orig_len  ($in[0], $in[2], $in[3]), '==', 20,     'test 36');

my $ok = 1;

for(1 .. 1000) {
  @in = (2 + int(rand(63)), 1 + int(rand(1000)), 2  + int(rand(63)));
  $in[3] = mpfr_min_inter_prec($in[0], $in[1], $in[2]);
  my $x = mpfr_max_orig_len($in[0], $in[2], $in[3]);
  if($x != $in[1] && $in[0] >= $in[2]) {
    warn "$x: @in\n";
    $ok = 0;
  }
}

cmp_ok($ok, '==', 1, 'test 37');




