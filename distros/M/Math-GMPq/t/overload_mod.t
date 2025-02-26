use strict;
use warnings;
use Math::GMPq qw(:mpq);

use Test::More;

my $num = Math::GMPq->new('197/3');
my $den = Math::GMPq->new('13/2');

cmp_ok($num % $den,  '==',  Math::GMPq->new('2/3'), "OBJ: '2/3' correctly returned");
cmp_ok($num % 6.5,   '==',  Math::GMPq->new('2/3'), "NV:  '2/3' correctly returned");
cmp_ok($num % '6.5', '==',  Math::GMPq->new('2/3'), "PV:  '2/3' correctly returned");

$den -= 0.5;

cmp_ok($num % $den, '==', Math::GMPq->new('17/3'), "OBJ: '17/3' correctly returned");
cmp_ok($num % 6,    '==', Math::GMPq->new('17/3'), "IV:  '17/3' correctly returned");
cmp_ok(200 % $den, '==', 2, "IV (switched):  '2' correctly returned");

$den += 0.5;

cmp_ok('200' % $den, '==', 5,     "PV (switched):  '5'   correctly returned");
cmp_ok('200.5' % $den, '==', 5.5, "NV (switched):  '5.5' correctly returned");

$num %= $den;
cmp_ok($num,  '==',  Math::GMPq->new('2/3'), "OBJ (%=) : '2/3' correctly returned");

my $iv = 45;
$iv %= $num;
cmp_ok(ref($iv), 'eq', 'Math::GMPq', "'%=' (switched): Math::GMPq object returned");
cmp_ok("$iv", 'eq', '1/3', "'%=' (switched): '1/3' correctly returned");
$iv %= 45;
cmp_ok("$iv", 'eq', '1/3', "Value is still '1/3'");

$num *= 217.6;

eval {require Math::GMPz;};

if(!$@) {
  if($Math::GMPz::VERSION >= 0.63) {
    cmp_ok($num % 15, '==', $num % Math::GMPz->new(15), "Math::GMPz object correctly evaluated");
    cmp_ok(ref(Math::GMPz->new(2500) % $num), 'eq', 'Math::GMPq', "Math::GMPz object (switched): returns a Math::GMPq object");
    cmp_ok(2500 % $num, '==', Math::GMPz->new(2500) % $num, "Math::GMPz object (switched): Math::GMPz object correctly evaluated");
  }
  else {
  warn "Skipped Math::GMPz tests - have Math-GMPz-$Math::GMPz::VERSION; need at least version 0.63";
  }
}
else {
  warn "Skipped Math::GMPz tests - couldn't load Math::GMPz";
}


done_testing();
