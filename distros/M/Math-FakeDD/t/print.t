
# Some basic checks on output functions.

use strict;
use warnings;
use Math::FakeDD qw(:all);

use Test::More;

my $fudd1 = Math::FakeDD->new('1e-09');

cmp_ok(dd_stringify($fudd1), 'eq', '[1e-09 -6.228159145777985e-26]'     , "decimal version of '1e-09' ok");
cmp_ok(unpackx($fudd1)     , 'eq', '[3e112e0be826d695 bab34674bfabb83b]', "'1e-09' unpacked ok"          );
cmp_ok(is_same_as(sprintx($fudd1), '[0x1.12e0be826d695p-30 -0x1.34674bfabb83bp-84]'), '==', 1,
                                                                       "hex representation of '1e-09' ok");
cmp_ok(dd_repro($fudd1), 'eq', '1e-09', "dd_repro() of '1e-09' ok");

cmp_ok(dd_dec($fudd1), 'eq',
       '1.0000000000000000000000000000000038785259781228752982302266735167412802775197245861511959053036235900435713119804859161376953125e-09',
        "dd_dec() of '1e-09' ok");

cmp_ok(dd_repro(dd_nan())  , 'eq', 'NaN' , "dd_repro stringifies NaN  as NaN" );
cmp_ok(dd_repro(dd_inf())  , 'eq', 'Inf' , "dd_repro stringifies +Inf as Inf" );
cmp_ok(dd_repro(dd_inf(-1)), 'eq', '-Inf', "dd_repro stringifies -Inf as -Inf");
cmp_ok(dd_repro(Math::FakeDD->new())  , 'eq', '0.0' , "dd_repro stringifies 0  as 0.0" );
cmp_ok(dd_repro(Math::FakeDD->new(1)) , 'eq', '1.0' , "dd_repro stringifies 1  as 1.0" );
cmp_ok(dd_repro(Math::FakeDD->new(-1)), 'eq', '-1.0', "dd_repro stringifies -1 as -1.0");
cmp_ok(dd_repro(Math::FakeDD->new(8)) , 'eq', '8.0' , "dd_repro stringifies 8  as 8.0" );
cmp_ok(dd_repro(Math::FakeDD->new(-8)), 'eq', '-8.0', "dd_repro stringifies -8 as -8.0");
cmp_ok(dd_repro(Math::FakeDD->new(512)) , 'eq', '512.0' , "dd_repro stringifies 512 as 512.0" );
cmp_ok(dd_repro(Math::FakeDD->new(-512)), 'eq', '-512.0', "dd_repro stringifies -512 as -512.0");

cmp_ok(dd_hex(Math::FakeDD->new())  , 'eq', '0x0p+0' , "dd_dec stringifies 0 as 0x0p+0" );
cmp_ok(dd_hex(dd_nan())  , 'eq', 'NaN' , "dd_hex stringifies NaN  as NaN" );
cmp_ok(dd_hex(dd_inf())  , 'eq', 'Inf' , "dd_hex stringifies +Inf as Inf" );
cmp_ok(dd_hex(dd_inf(-1)), 'eq', '-Inf', "dd_hex stringifies -Inf as -Inf");

cmp_ok(dd_dec(Math::FakeDD->new())  , 'eq', '0.0' , "dd_dec stringifies 0 as 0.0" );
cmp_ok(dd_dec(dd_nan())  , 'eq', 'NaN' , "dd_dec stringifies NaN  as NaN" );
cmp_ok(dd_dec(dd_inf())  , 'eq', 'Inf' , "dd_dec stringifies +Inf as Inf" );
cmp_ok(dd_dec(dd_inf(-1)), 'eq', '-Inf', "dd_dec stringifies -Inf as -Inf");

for(0, '256.125', '0.1', '-1.3', 0.14 / 10) {
  my $hex = dd_hex(Math::FakeDD->new($_));
  cmp_ok(Math::FakeDD->new($hex), '==', Math::FakeDD->new($_), "dd_hex() ok with '$_'");
}

for(1 .. 1000) {
  my $sign = '';
  $sign = '-' unless $_ % 5;
  my $s0 = rand();
  $s0 = (split /e/i, $s0)[0] if $s0 =~ /e/i;
  my $e = 'e';
  $e = 'e-'if $_ % 3;
  my $pow = int(rand(100));

  my $str = $sign . $s0 . $e . $pow;

  my $n = Math::FakeDD->new($str);
  cmp_ok(dd_repro_test(dd_repro($n), $n), '==', 15, "dd_repro_test passes for $str");

  my $hex = dd_hex($n);

  cmp_ok(dd_hex(Math::FakeDD->new($hex)), '==', $n, "dd_hex() ok with '$str'");
}

{
my $str = '0.299155617363080494897076277993619e4';
my $dd = Math::FakeDD->new('0.299155617363080494897076277993619e4'); # [0xb.af8e616523348p+8 -0x8p-47]
                                                                     # or (equivalently)
                                                                     # [0x1.75f1cc2ca4669p+11 -0x1p-44]
cmp_ok(dd_repro_test(dd_repro($dd), $dd), '==', 15, "dd_repro_test passes for $dd"); # 0xb.af8e616523347p+8
my $hex = dd_hex($dd);
cmp_ok(dd_hex(Math::FakeDD->new($hex)), '==', $dd, "dd_hex() ok with '$str'");

my $dd_up = dd_nextup($dd);
cmp_ok($dd_up, '>', $dd, "$dd_up > $dd");
cmp_ok(dd_repro_test(dd_repro($dd_up), $dd_up), '==', 15, "dd_repro_test passes for $dd_up");
$hex = dd_hex($dd_up);
cmp_ok(dd_hex(Math::FakeDD->new($hex)), '==', $dd_up, "dd_hex() ok with $dd_up");

my $dd_down = dd_nextdown($dd);
cmp_ok($dd_down, '<', $dd, "$dd_down < $dd");
cmp_ok(dd_repro_test(dd_repro($dd_down), $dd_down), '==', 15, "dd_repro_test passes for $dd_down");
$hex = dd_hex($dd_down);
cmp_ok(dd_hex(Math::FakeDD->new($hex)), '==', $dd_down, "dd_hex() ok with $dd_down");
}

done_testing();

sub is_same_as {
  # There's no guarantee that "%a" outputs will be as expected.
  # We check here that the represented values are identical.

  my $arg1 = shift;
  my $arg2 = shift;

  return 1 if($arg1 eq $arg2);

  my $m1 = Math::MPFR::Rmpfr_init2(53);
  my $m2 = Math::MPFR::Rmpfr_init2(53);

  $arg1 =~ s/\[|\]//g;
  $arg2 =~ s/\[|\]//g;

  my @args1 = split /\s/, $arg1;
  my @args2 = split /\s/, $arg2;

  die "Bad split in is_same_as()" if ( @args1 != 2 || @args2 != 2 );

  Math::MPFR::Rmpfr_set_str($m1, $args1[0], 0, 0);
  Math::MPFR::Rmpfr_set_str($m2, $args1[0], 0, 0);

  return 0 if $m1 != $m2;

  Math::MPFR::Rmpfr_set_str($m1, $args1[1], 0, 0);
  Math::MPFR::Rmpfr_set_str($m2, $args1[1], 0, 0);

  return 0 if $m1 != $m2;
  return 1;
}


