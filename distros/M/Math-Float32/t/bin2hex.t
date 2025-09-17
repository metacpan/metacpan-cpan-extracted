use strict;
use warnings;

use Math::Float32 qw(:all);

my $have_mpfr = 0;
eval { require Math::MPFR;};
$have_mpfr = 1 unless $@;

Math::MPFR::Rmpfr_set_default_prec(24) if $have_mpfr;

use Test::More;

if($Math::Float32::broken_signed_zero) {
  warn "\n 3 signed zero tests will be skipped because",
       "\n this system does not support negative zero\n";
}

for my $bin ( '0b11101101', '-0B11101101',
              '0b0011101101', '-0B0011101101',
              '0b00011101101', '-0B00011101101',
              '0b00011101101p-11', '-0B00011101101p-11',
              '0b00011101101p+8', '-0B00011101101p+8',
              '0B11101101p-11', '-0b11101101e-11',
              '0B11101101p+11', '-0b11101101E+11',
              '0B00.011101101p-11', '-0b00.011101101p-11',
              '0B000.0011101101p+11', '-0b0.0011101101E+11',
              '0b111.01101', '-0B111.01101',
              '0b111.01101e-7', '-0B111.01101E-7',
              '0b111.01101P+7', '-0B111.01101p+7',
              '0b1.1101101e-7', '-0B1.1101101E-7',
              '0b1.1101101P+17', '-0B1.1101101p+17',
              '0b1.1101101', '-0B1.1101101',
              '0b.11101101e-7', '-0B.11101101E-7',
              '0b.11101101P+17', '-0B.11101101p+17',
              '0b00.00000000p0', '-0B00.0000000p10',
              '0b00.00000000e0', '-0B00.0000000e-10',
              '0b0', '-0B0',
              '0b0.0', '-0B0.0',
              '0b000.0', '-0B000.0',
              '0b0000.000', '-0B0000.0000',
              '0b0010.0', '-0b0010.0'
            ) {
  like($bin, qr/^[\-\+]?0[bB]/, "$bin is a basic match");
  cmp_ok( Math::Float32->new(Math::Float32::bin2hex($bin)), '==', Math::Float32->new($bin), "$bin: ok");

  if($have_mpfr) {
    cmp_ok( Math::MPFR->new(Math::Float32::bin2hex($bin)), '==', Math::MPFR->new($bin), "MPFR ($bin): ok");
  }
}

my $s = '-0b11.01';
my $obj = Math::Float32->new(4);

cmp_ok($obj + $s, '==', '0.75', "Addition ok");
cmp_ok($obj - $s, '==', '7.25', "Subtraction ok");
cmp_ok($s - $obj, '==', '-7.25', "Complementary subtraction ok");
cmp_ok($obj * $s, '==', '-13', "Multiplication ok");
cmp_ok($obj / '0b0010.0', '==', '2', "Division ok");
cmp_ok('0b100p-1' / $obj, '==', '0.5', "Inverse division ok");
cmp_ok($obj % '0b001.1', '==', '1', "Fmod ok");
cmp_ok('0b11p-1' % $obj, '==', '1.5', "Inverse fmod ok");
cmp_ok($obj ** '0b0010.0', '==', '16', "Pow ok");
cmp_ok('0b11p0' ** $obj, '==', '81', "Inverse pow ok");

cmp_ok($obj, '<', '0b1.1p49', "< ok");
cmp_ok($obj, '<=', '0b1.1p49', "<= (<) ok");
cmp_ok($obj, '<=', '0B100', "<= (=) ok");
cmp_ok($obj, '==', '0B100', "== ok");
cmp_ok('0B100', '==', $obj, "== (reversed) ok");
cmp_ok(($obj <=> '0b1.1p49'), '==', -1, "<=> ok");
cmp_ok(('0b1.1p49' <=> $obj), '==', 1, "<=> (reversed) ok");

cmp_ok($obj, '>', '0b1.1p-49', "> ok");
cmp_ok($obj, '>=', '0b1.1p-49', ">= (>) ok");
cmp_ok($obj, '>=', '0B100', ">= (=) ok");

cmp_ok('0b1.1p-49', '<', $obj, "< (reversed) ok");
cmp_ok('0b1.1p-49', '<=', $obj, "<= (reversed) (<) ok");
cmp_ok('0B100', '<=', $obj, "<= (reversed) (=) ok");

cmp_ok('0b1.1p49', '>', $obj, "> (reversed) ok");
cmp_ok('0b1.1p49', '>=', $obj, ">=  reversed)(>) ok");
cmp_ok('0B100', '>=', $obj, ">= (=) ok");


cmp_ok(Math::Float32->new('0b0010.0'), '==', '2', "'0b0010.0' assessed correctly");
cmp_ok(Math::Float32->new('0b10.0'), '==', '2', "'0b10.0' assessed correctly");
cmp_ok(Math::Float32->new('0b0010.'), '==', '2', "'0b0010.' assessed correctly");
cmp_ok(Math::Float32->new('0b10.'), '==', '2', "'0b10.' assessed correctly");
cmp_ok(Math::Float32->new('0b10'), '==', '2', "'0b10' assessed correctly");
cmp_ok(Math::Float32->new('0b100p-1'), '==', '2', "'0b100p-1' assessed correctly");
cmp_ok(Math::Float32->new('0b0010'), '==', '2', "'0b0010' assessed correctly");
cmp_ok(Math::Float32->new('0b00100p-1'), '==', '2', "'0b100p-1' assessed correctly");
cmp_ok(Math::Float32->new('0b0010.01'), '==', '2.25', "'0b0010.01' assessed correctly");
cmp_ok(Math::Float32->new('0b10.01'), '==', '2.25', "'0b10.01' assessed correctly");
cmp_ok(Math::Float32->new('0b0010.01000'), '==', '2.25', "'0b0010.01000' assessed correctly");
cmp_ok(Math::Float32->new('0b10.01000'), '==', '2.25', "'0b10.01000' assessed correctly");
cmp_ok(Math::Float32->new('0b0010.0100'), '==', '2.25', "'0b0010.0100' assessed correctly");
cmp_ok(Math::Float32->new('0b10.0100'), '==', '2.25', "'0b10.0100' assessed correctly");
cmp_ok(Math::Float32->new('0b001.1'), '==', '1.5', "'0b001.1' assessed correctly");
cmp_ok(Math::Float32->new('0b01.1'), '==', '1.5', "'0b01.1' assessed correctly");
cmp_ok(Math::Float32->new('0b1.1'), '==', '1.5', "'0b1.1' assessed correctly");
cmp_ok(Math::Float32->new('0b11p-1'), '==', '1.5', "'0b11p-1' assessed correctly");
cmp_ok(Math::Float32->new('-0b1.00001p+3'), '==', '-8.25', "'0b1.00001p+3' assessed correctly");
cmp_ok(Math::Float32->new('-0b100.001E+1'), '==', '-8.25', "'0b100.001E+1' assessed correctly");
cmp_ok(Math::Float32->new('-0b.001'), '==', '-0.125', "'0b.001' assessed correctly");
cmp_ok(Math::Float32->new('-0b.001E-1'), '==', '-0.0625', "'0b.001E-1' assessed correctly");
cmp_ok(Math::Float32->new('-0b.001p+1'), '==', '-0.25', "'0b.001p+1' assessed correctly");
my $whitespace = " \t \n  \n ";
cmp_ok(Math::Float32->new("${whitespace}-0b.001p+1"), '==', '-0.25', "'<whitespace>-0b.001p+1' assessed correctly");
cmp_ok(sprintf("%s", Math::Float32->new('0b.')), 'eq', '0', "'0b.' assessed correctly");

unless($Math::Float32::broken_signed_zero) {
  cmp_ok(sprintf("%s", Math::Float32->new('-0b.')), 'eq', '-0', "'-0b.' assessed correctly");
}
else { warn "Skipping signed zero test " }

cmp_ok(sprintf("%s", Math::Float32->new('0b')), 'eq', '0', "'0b' assessed correctly");

unless($Math::Float32::broken_signed_zero) {
  cmp_ok(sprintf("%s", Math::Float32->new('-0b')), 'eq', '-0', "'-0b' assessed correctly");
}
else { warn "Skipping signed zero test " }

cmp_ok(sprintf("%s", Math::Float32->new('0b0.0')), 'eq', '0', "'0b0.0' assessed correctly");

unless($Math::Float32::broken_signed_zero) {
  cmp_ok(sprintf("%s", Math::Float32->new('-0b0.0')), 'eq', '-0', "'-0b0.0' assessed correctly");
}
else { warn "Skipping signed zero test " }

done_testing();
