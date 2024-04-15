use strict;
use warnings;

use Math::Int113;

use Test::More;

my $ret;

my $t1 = Math::Int113->new(10384593717069655257060992658440191);
cmp_ok($t1, '==', 10384593717069655257060992658440191, '10384593717069655257060992658440191assigns ok');

my $t2 = -$t1;
cmp_ok($t2, '==', -10384593717069655257060992658440191, '-10384593717069655257060992658440191 assigns ok');

eval { my $x = $t1 + 1;};
like ($@, qr/overflows 113 bits/, '10384593717069655257060992658440191 + 1 overflows');

eval { my $x = $t2 - 1;};
like ($@, qr/overflows 113 bits/, '-10384593717069655257060992658440191 - 1 overflows');

eval { my $x = Math::Int113->new(10384593717069655257060992658440192);};
like ($@, qr/overflows 113 bits/, '10384593717069655257060992658440192 overflows');

eval { my $x = Math::Int113->new(-10384593717069655257060992658440192);};
like ($@, qr/overflows 113 bits/, '-10384593717069655257060992658440192 overflows');

my $inf = 99 ** (99 ** 99);

eval { my $x = Math::Int113->new($inf);};
like ($@, qr/overflows 113 bits/, 'Inf overflows');

eval { my $x = Math::Int113->new(-$inf);};
like ($@, qr/overflows 113 bits/, '-Inf overflows');

my $nan = $inf /  $inf;

if($nan != $nan) {
  eval { my $x = Math::Int113->new($nan);};
  like ($@, qr/overflows 113 bits/, 'NaN overflows');
}

eval{ $ret = Math::Int113->new(10) & $nan; };
like ($@, qr/overflow/i, '& NaN overflows');

eval{ $ret = Math::Int113->new(10) | $nan; };
like ($@, qr/overflow/i, '| NaN overflows');

eval{ $ret = Math::Int113->new(10) ^ $nan; };
like ($@, qr/overflow/i, '^ NaN overflows');

require Math::BigInt;
my $v1 = Math::BigInt->new(18446744073709551615) ** 2;
my $v2 = Math::Int113->new(111);

cmp_ok($v1, '==', Math::BigInt->new('340282366920938463426481119284349108225'), "Math::BigInt object assigned correctly");
my $mbi = $v1 + $v2;
cmp_ok(ref($mbi), 'eq', 'Math::BigInt', "Math::BigInt object as expected");
cmp_ok($mbi, '==', Math::BigInt->new('340282366920938463426481119284349108336'), "Math::BigInt + Math::Int113 ok");

eval { my $x = $v2 + $v1;};
like ($@, qr/given to overloaded addition/, 'Math::Int113 + Math::BigInt overflows as expected');

my $mi113 = $v2 + Math::BigInt->new(12345678);
cmp_ok(ref($mi113), 'eq', 'Math::Int113', "Math::Int113 object as expected");
cmp_ok($mi113, '==', Math::Int113->new(12345789), "Math::Int113 + Math::BigInt ok");



done_testing();
