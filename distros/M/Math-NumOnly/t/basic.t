use strict;
use warnings;
use Math::NumOnly;
use Test::More;

my ($new, $dummy);

cmp_ok($Math::NumOnly::VERSION, 'eq', '0.01', "version number is as expected");

eval {$new = Math::NumOnly->new(undef);};
like ($@, qr/^Bad argument \(or no argument\)/, 'undef is invalid arg');

my $str = '3';
eval {$new = Math::NumOnly->new($str);};
like ($@, qr/^Bad argument \(or no argument\)/, 'PV is invalid arg');

my $num = $str + 1;
eval {$new = Math::NumOnly->new($str);};
like ($@, qr/^Bad argument \(or no argument\)/, 'PVIV is invalid arg');

# The following might not be as desired ... but the addition that was done
# in order to create $num was NOT type-checked.
cmp_ok(Math::NumOnly->new($num), '==', 4, "IV derived from string is ok");

$new = Math::NumOnly->new(11);

cmp_ok($new <=> 11, '==', 0, "overloaded '<=>' ok for equivalent values");
cmp_ok(11 <=> $new, '==', 0, "overloaded '<=>' (inverted) ok for equivalent values");

cmp_ok($new <=> 22, '<', 0, "overloaded '<=>' ok for a < b");
cmp_ok(22 <=> $new, '>', 0, "overloaded '<=>' (inverted) ok for b > a");

cmp_ok($new <=> -11, '>', 0, "overloaded '<=>' ok for a > b");
cmp_ok(-11 <=> $new, '<', 0, "overloaded '<=>' (inverted) ok for b < a");

cmp_ok($new, '==', 11, "overloaded '==' is ok");
cmp_ok(11, '==', $new, "overloaded '==' (inverted) is ok");

cmp_ok($new, '>', -11, "overloaded '>' is ok");
cmp_ok(-11, '<', $new, "overloaded '<' (inverted) is ok");

cmp_ok($new, '<', 22, "overloaded '<' is ok");
cmp_ok(22, '>', $new, "overloaded '>' (inverted) is ok");

cmp_ok($new, '>=', -11, "overloaded '>=' is ok for a > b ");
cmp_ok(-11, '<=', $new, "overloaded '<=' (inverted) is ok for b < a");

cmp_ok($new, '<=', 22, "overloaded '<=' is ok for a < b");
cmp_ok(22, '>=', $new, "overloaded '>=' (inverted) is ok for b > a");

cmp_ok($new, '>=', 11, "overloaded '>=' is ok for a == b ");
cmp_ok(11, '<=', $new, "overloaded '<=' (inverted) is ok for b == a");

cmp_ok($new, '<=', 11, "overloaded '<=' is ok for a == b");
cmp_ok(11, '>=', $new, "overloaded '>=' (inverted) is ok for b == a");

cmp_ok($new + 4, '==', 15, 'oload_add is correct with IV');
cmp_ok($new + 4.3, '==', 15.3, 'oload_add is correct with NV');
cmp_ok($new + Math::NumOnly->new(4.5), '==', 15.5, 'oload_add is correct with NV');
eval{$dummy = $new + '5';};
like ($@, qr/^Bad argument given/, 'oload_add croaks with string arg');

cmp_ok($new + 4, '==', 15, 'oload_add is correct with IV');
cmp_ok(4 + $new, '==', 15, 'oload_add is correct with IV (inverted)');
cmp_ok($new + 4.3, '==', 15.3, 'oload_add is correct with NV');
cmp_ok($new + Math::NumOnly->new(4.5), '==', 15.5, 'oload_add is correct with M::NO object');
eval{$dummy = $new + '5';};
like ($@, qr/^Bad argument given/, 'oload_add croaks with string arg');

$new++;

cmp_ok($new, '==', 12, "oload_inc increments correctly");

cmp_ok($new * 4, '==', 48, 'oload_mul is correct with IV');
cmp_ok(4 * $new, '==', 48, 'oload_mul is correct with IV (inverted)');
cmp_ok($new * 4.125, '==', 49.5, 'oload_mul is correct with NV');
cmp_ok($new * Math::NumOnly->new(4.125), '==', 49.5, 'oload_mul is correct with M::NO object');
eval{$dummy = $new * '5';};
like ($@, qr/^Bad argument given/, 'oload_mul croaks with string arg');

cmp_ok($new / 4, '==', 3, 'oload_div is correct with IV');
cmp_ok(4 / $new, '==', 1 / 3, 'oload_div is correct with IV (inverted)');
cmp_ok($new / 0.125, '==', 96, 'oload_div is correct with NV');
cmp_ok($new / Math::NumOnly->new(2), '==', 6, 'oload_div is correct with M::NO object');
eval{$dummy = $new / '5';};
like ($@, qr/^Bad argument given/, 'oload_div croaks with string arg');

cmp_ok($new - 4, '==', 8, 'oload_sub is correct with IV');
cmp_ok(4 - $new, '==', -8, 'oload_sub is correct with IV (inverted)');
cmp_ok($new - 0.125, '==', 11.875, 'oload_sub is correct with NV');
cmp_ok($new - Math::NumOnly->new(2), '==', 10, 'oload_sub is correct with M::NO object');
eval{$dummy = $new - '5';};
like ($@, qr/^Bad argument given/, 'oload_sub croaks with string arg');

$new--;

cmp_ok($new, '==', 11, "oload_dec decrements correctly");

cmp_ok($new ** 2, '==', 121, 'oload_pow is correct with IV');
cmp_ok(2 ** $new, '==', 2 ** 11, 'oload_pow is correct with IV (inverted)');
cmp_ok($new ** 0.5, '==', sqrt(11), 'oload_pow is correct with NV');
cmp_ok($new ** Math::NumOnly->new(0.5), '==', sqrt(11), 'oload_pow is correct with M::NO object');
eval{$dummy = $new ** '5';};
like ($@, qr/^Bad argument given/, 'oload_pow croaks with string arg');

require Math::BigInt;
cmp_ok(Math::NumOnly::is_ok(Math::BigInt->new(2)), '==', 0, 'Math::BigInt object is rejected');

eval { Math::NumOnly->new(7) + Math::BigInt->new(8); };
like ($@, qr/^Bad argument given/, 'Math::BigInt object not allowed in addition (+)');

eval { Math::NumOnly->new(8) - Math::BigInt->new(7); };
like ($@, qr/^Bad argument given/, 'Math::BigInt object not allowed in subtraction (-)');

done_testing();
