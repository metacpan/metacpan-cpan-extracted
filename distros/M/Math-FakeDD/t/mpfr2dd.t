
# Check for errors due to double rounding.

use warnings;
use strict;
use Math::FakeDD qw(:all);
use Test::More;

for(1..2000) {
  my $s1 = rand() . 'e' .  int(rand(10));
  my $s2 = rand() . 'e-' . int(rand(100));

  my $fudd1 = Math::FakeDD->new($s1);
  my $fudd2 = Math::FakeDD->new($s2);


  cmp_ok(dd_add($fudd1, $fudd2), '==', Math::FakeDD::dd_add_4196($fudd1, $fudd2),
                                       "ADD: no error with $fudd1 and $fudd2");

  cmp_ok(dd_mul($fudd1, $fudd2), '==', Math::FakeDD::dd_mul_4196($fudd1, $fudd2),
                                       "MUL: no error with $fudd1 and $fudd2");

  cmp_ok(dd_sub($fudd1, $fudd2), '==', Math::FakeDD::dd_sub_4196($fudd1, $fudd2),
                                       "SUB: no error with $fudd1 and $fudd2");

  cmp_ok(dd_div($fudd1, $fudd2), '==', Math::FakeDD::dd_div_4196($fudd1, $fudd2),
                                       "DIV: no error with $fudd1 and $fudd2");

}

my $m1 = Math::MPFR::Rmpfr_init2(2098);
my $m2 = Math::MPFR::Rmpfr_init2(2112);

my $skips = 0;
my $its = 1600;

for(1 .. $its) {
 my $s = '1.' . ('0' x 1067) . randbin(10);

 Math::MPFR::Rmpfr_set_str($m1, $s, 2, 0);
 Math::MPFR::Rmpfr_set_str($m2, $s, 2, 0);

 my $first = mpfr_any_prec2dd($m2);

 cmp_ok(mpfr2dd($m1), '==', $first, "assign ..." . substr($s, -12, 12) . "ok");

 cmp_ok($first, '==', Math::FakeDD->new(Math::MPFR::decimalize($m1)), "mpfr_any_prec2dd agrees with new()");

 if(substr($s, -20, 17) !~ /1/) {
   cmp_ok($first->{lsd}, '<=', 2 ** -1073, "less significant double <= DBL_DENORM_MIN");
   $skips++;
 }
 else {
   cmp_ok($first->{lsd}, '!=', 0, "less significant double is not 0");
 }
}

cmp_ok($skips, '<', $its / 32, "1a: random selection is not obviously flawed");
cmp_ok($skips, '>', 0        , "1b: random selection is not obviously flawed");

$skips = 0;

for(1 .. $its) {
 my $s = '1.' . ('1' x 1067) . randbin(10);

 Math::MPFR::Rmpfr_set_str($m1, $s, 2, 0);
 Math::MPFR::Rmpfr_set_str($m2, $s, 2, 0);

 my $first = mpfr2dd($m1);

 cmp_ok($first, '==', mpfr_any_prec2dd($m2), "assign ..." . substr($s, -12, 12) . "ok");

 cmp_ok($first, '==', Math::FakeDD->new(Math::MPFR::decimalize($m2)), "mpfr2dd agrees with new()");

 if(substr($s, -20, 18) !~ /0/) { $skips++ } # lsd should be zero
 else {
   cmp_ok($first->{lsd}, '!=', 0, "less significant double is not 0");
 }
}

cmp_ok($skips, '<', $its / 50, "2a: random selection is not obviously flawed");
cmp_ok($skips, '>', 0        , "2b: random selection is not obviously flawed");

done_testing();

sub randbin {
  my $ret = '';
  $ret .= int rand 2 for(1 .. $_[0]);
  return $ret;
}

__END__
