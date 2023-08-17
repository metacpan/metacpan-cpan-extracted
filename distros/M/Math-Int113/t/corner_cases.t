use strict;
use warnings;

use Math::Int113;

use Test::More;

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

done_testing();
