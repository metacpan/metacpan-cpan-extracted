use strict;
use warnings;
use Math::Float32 qw(:all);

#my $have_mpfr = 0;
#eval { require Math::MPFR;};
#$have_mpfr = 1 unless $@;

use Test::More;
cmp_ok(unpack_flt_hex($Math::Float32::flt_DENORM_MIN), 'eq', '00000001', "DENORM_MIN unpacks correctly");
cmp_ok(unpack_flt_hex($Math::Float32::flt_DENORM_MAX), 'eq', '007FFFFF', "DENORM_MAX unpacks correctly");
cmp_ok(unpack_flt_hex($Math::Float32::flt_NORM_MIN),   'eq', '00800000', "NORM_MIN unpacks correctly");
cmp_ok(unpack_flt_hex($Math::Float32::flt_NORM_MAX),   'eq', '7F7FFFFF', "NORM_MAX unpacks correctly");
cmp_ok(unpack_flt_hex(sqrt(Math::Float32->new(2))),    'eq', '3FB504F3', "sqrt 2 unpacks correctly");
cmp_ok(unpack_flt_hex(Math::Float32->new('5e-41')),    'eq', '00008B61', "'5e-41' unpacks correctly");

cmp_ok(unpack_flt_hex(-$Math::Float32::flt_DENORM_MIN), 'eq', '80000001', "-DENORM_MIN unpacks correctly");
cmp_ok(unpack_flt_hex(-$Math::Float32::flt_DENORM_MAX), 'eq', '807FFFFF', "-DENORM_MAX unpacks correctly");
cmp_ok(unpack_flt_hex(-$Math::Float32::flt_NORM_MIN),   'eq', '80800000', "-NORM_MIN unpacks correctly");
cmp_ok(unpack_flt_hex(-$Math::Float32::flt_NORM_MAX),   'eq', 'FF7FFFFF', "-NORM_MAX unpacks correctly");
cmp_ok(unpack_flt_hex(-(sqrt(Math::Float32->new(2)))),  'eq', 'BFB504F3', "-(sqrt 2) unpacks correctly");
cmp_ok(unpack_flt_hex(Math::Float32->new('-5e-41')),    'eq', '80008B61', "'-5e-41' unpacks correctly");

{
  my $inc = Math::Float32->new('0');
  my $dec = Math::Float32->new('-0');

  my ($iv_inc, $iv_dec, $iv_store) = (0, 0, 0);

  cmp_ok(unpack_flt_hex($inc), 'eq', '00000000', " 0 unpacks to 00000000");
  cmp_ok(unpack_flt_hex($dec), 'eq', '80000000', "-0 unpacks to 80000000");

  my $pack = pack_flt_hex('00000000');
  cmp_ok(ref($pack), 'eq', "Math::Float32", "'00000000': pack returns Math::Float32 object");
  cmp_ok(is_flt_zero($pack), '==', 1, "returns 0 as expected");

  $pack = pack_flt_hex('80000000');
  cmp_ok(ref($pack), 'eq', "Math::Float32", "'80000000': pack returns Math::Float32 object");
  cmp_ok(is_flt_zero($pack), '==', -1, "returns -0 as expected");

  for(1..2060) {
    flt_nextabove($inc);
    flt_nextbelow($dec);
    my $unpack_inc = unpack_flt_hex($inc);
    my $pack_inc = pack_flt_hex($unpack_inc);
    cmp_ok($pack_inc, '==', $inc, "$unpack_inc: round_trip ok");

    my $unpack_dec = unpack_flt_hex($dec);
    my $pack_dec = pack_flt_hex($unpack_dec);
    cmp_ok($pack_dec, '==', $dec, "$unpack_dec: round_trip ok");

    cmp_ok(length($unpack_inc), '==', 8, "length($unpack_inc) == 8");
    cmp_ok(length($unpack_dec), '==', 8, "length($unpack_inc) == 8");

    $iv_inc = hex($unpack_inc);
    cmp_ok($iv_inc - $iv_store, '==', 1, "inc has been incremented to $unpack_inc");
    $iv_dec = hex($unpack_dec);
    cmp_ok($iv_dec - $iv_inc, '==', 0x80000000, "dec has been decremented to $unpack_dec");

    $iv_store = $iv_inc;
  }
}

{
  my $inc = Math::Float32->new('-inf');
  my $dec = Math::Float32->new('inf');

  my ($iv_inc, $iv_dec, $iv_store) = (0, 0, hex('7F800000'));

  cmp_ok(is_flt_inf($inc), '==', -1, "is -inf as expected");
  cmp_ok(is_flt_inf($dec), '==', 1, "is +inf as expected");

  cmp_ok(unpack_flt_hex($inc), 'eq', 'FF800000', " -inf unpacks to FF800000");
  cmp_ok(unpack_flt_hex($dec), 'eq', '7F800000', "+inf unpacks to 7F800000");

  my $pack = pack_flt_hex('FF800000');
  cmp_ok(ref($pack), 'eq', "Math::Float32", "'FF800000': pack returns Math::Float32 object");
  cmp_ok(is_flt_inf($pack), '==', -1, "returns -inf as expected");

  $pack = pack_flt_hex('7F800000');
  cmp_ok(ref($pack), 'eq', "Math::Float32", "'7F800000': pack returns Math::Float32 object");
  cmp_ok(is_flt_inf($pack), '==', 1, "returns +inf as expected");

  for(1..2060) {
    flt_nextabove($inc);
    flt_nextbelow($dec);
    my $unpack_inc = unpack_flt_hex($inc);
    my $pack_inc = pack_flt_hex($unpack_inc);
    cmp_ok($pack_inc, '==', $inc, "$unpack_inc: round_trip ok");

    my $unpack_dec = unpack_flt_hex($dec);
    my $pack_dec = pack_flt_hex($unpack_dec);
    cmp_ok($pack_dec, '==', $dec, "$unpack_dec: round_trip ok");

    cmp_ok(length($unpack_inc), '==', 8, "length($unpack_inc) == 8");
    cmp_ok(length($unpack_dec), '==', 8, "length($unpack_inc) == 8");

    $iv_dec = hex($unpack_dec);
    cmp_ok($iv_store - $iv_dec, '==', 1, "dec has been decremented to $unpack_dec");
    $iv_inc = hex($unpack_inc);
    cmp_ok($iv_inc - $iv_dec, '==', 0x80000000, "inc has been incremented to $unpack_inc");

    $iv_store = $iv_dec;
  }
}

{

  # Check for values next to the subnormal/normal boundary
  my $inc = Math::Float32->new($Math::Float32::flt_DENORM_MAX);
  my $dec = Math::Float32->new(-$Math::Float32::flt_DENORM_MAX);

  $inc -= 10 * $Math::Float32::flt_DENORM_MIN;
  $dec += 10 * $Math::Float32::flt_DENORM_MIN;

  my ($iv_inc, $iv_dec, $iv_store) = (0, 0, hex(unpack_flt_hex($inc)));

  for(1..20) {
    flt_nextabove($inc);
    flt_nextbelow($dec);
    my $unpack_inc = unpack_flt_hex($inc);
    my $pack_inc = pack_flt_hex($unpack_inc);
    cmp_ok($pack_inc, '==', $inc, "$unpack_inc: round_trip ok");

    my $unpack_dec = unpack_flt_hex($dec);
    my $pack_dec = pack_flt_hex($unpack_dec);
    cmp_ok($pack_dec, '==', $dec, "$unpack_dec: round_trip ok");

    cmp_ok(length($unpack_inc), '==', 8, "length($unpack_inc) == 8");
    cmp_ok(length($unpack_dec), '==', 8, "length($unpack_inc) == 8");

    $iv_inc = hex($unpack_inc);
    cmp_ok($iv_inc - $iv_store, '==', 1, "inc has been incremented to $unpack_inc");
    $iv_dec = hex($unpack_dec);
    cmp_ok($iv_dec - $iv_inc, '==', 0x80000000, "dec has been decremented to $unpack_dec");

    $iv_store = $iv_inc;
  }
}

done_testing();
