use strict;
use warnings;
use Math::JS;
use Test::More;

my ($new, $dummy);

cmp_ok($Math::JS::VERSION, 'eq', '0.04', "version number is as expected");

eval {$new = Math::JS->new(undef);};
like ($@, qr/^Bad argument \(or no argument\)/, 'undef is invalid arg');

my $v = Math::JS->new(1 / 10);

cmp_ok($v, '==', 0.1, "1/10 == 0.1");

$v = Math::JS->new(1.4 / 10);
cmp_ok($v, '==', 0.13999999999999999, "1.4/10 == 0.13999999999999999");
cmp_ok("$v", '==', 1.4 / 10, "1.4/10 eq 0.13999999999999999");

$v = Math::JS->new(2);
my $n = $v ** 0.5;
cmp_ok($n, '==', 1.4142135623730951E0, "2 ** 0.5 == 1.4142135623730951");
cmp_ok("$n", '==', 2 ** 0.5, "2 ** 0.5 eq 1.4142135623730951");

$v = Math::JS->new(2147483647);
$n = $v & 429496729;
cmp_ok($n->{val}, '==', 429496729, "2147483647 & 429496729 == 429496729");
cmp_ok($v & 429496729, '==', 429496729, "objects: 2147483647 & 429496729 == 429496729");
cmp_ok(ref($v & 429496729), 'eq', "Math::JS", "'and' returns Math::JS object");

$n = $v | 429496729;
cmp_ok($n->{val}, '==', 2147483647, "2147483647 | 429496729 == 2147483647");
cmp_ok($v | 429496729, '==', 2147483647, "objects: 2147483647 | 429496729 == 2147483647");
cmp_ok(ref($v | 429496729), 'eq', "Math::JS", "'ior' returns Math::JS object");

$n = $v ^ 429496729;
cmp_ok($n->{val}, '==', 1717986918, "2147483647 ^ 429496729 == 1717986918");
cmp_ok($v ^ 429496729, '==', 1717986918, "objects: 2147483647 ^ 429496729 == 1717986918");
cmp_ok(ref($v ^ 429496729), 'eq', "Math::JS", "'xor' returns Math::JS object");

$v = Math::JS->new(401);
$n = $v >> 1;
cmp_ok($n->{val}, '==', 200, "401 >> 1 == 200");
cmp_ok($n->{type}, 'eq', 'sint32', ">> operation specifies 'sint32' type");

$n = $v << 1;
cmp_ok($n->{val}, '==', 802, "401 << 1 == 802");
cmp_ok($n->{type}, 'eq', 'sint32', "<< operation specifies 'sint32' type");

$v = Math::JS->new(2147483647);
cmp_ok($v->{type}, 'eq', 'sint32', "2147483647 is 'sint32' type");

$v = Math::JS->new(2147483648);
cmp_ok($v->{type}, 'eq', 'uint32', "2147483648 is 'uint32' type");

$v = Math::JS->new(4294967295);
cmp_ok($v->{type}, 'eq', 'uint32', "4294967295 is 'uint32' type");

# Sanity Check:
my $wanted = Math::JS->new(0.13999999999999999);
my $tester = Math::JS->new(unpack("d", pack "d", 1.4) / 10);
cmp_ok($tester, '==', $wanted, "use of unpack/pack works as expected");
cmp_ok("$tester", 'eq', "$wanted", "string equality is retained");
cmp_ok("$tester", 'eq', '0.13999999999999999', "string is as expected");

my $js = Math::JS->new(Math::JS::MAX_SLONG);
cmp_ok($js->{type}, 'eq', 'sint32', "$js is 'sint32'");
$js += 10;
cmp_ok($js->{type}, 'eq', 'uint32', "+= modifies type to 'uint32'");
$js += Math::JS::MAX_ULONG;
cmp_ok($js->{type}, 'eq', 'number', "+= modifies type to 'number'");

$js = Math::JS->new(Math::JS::MAX_SLONG);
cmp_ok($js->{type}, 'eq', 'sint32', "$js is 'sint32'");
$js *= 2;
cmp_ok($js->{type}, 'eq', 'uint32', "*= modifies type to 'uint32' when appropriate");
$js *= 2;
cmp_ok($js->{type}, 'eq', 'number', "*= modifies type to 'number' when appropriate");

$js = Math::JS->new(Math::JS::MAX_ULONG + 10);
cmp_ok($js->{type}, 'eq', 'number', "$js is 'number'");
$js -= 12;
cmp_ok($js->{type}, 'eq', 'uint32', "-= modifies type to 'uint32' when appropriate");
$js -= (Math::JS::MAX_ULONG - 100);
cmp_ok($js->{type}, 'eq', 'sint32', "-= modifies type to 'sint32' when appropriate");

$js = Math::JS->new(17);
cmp_ok($js->{type}, 'eq', 'sint32', "$js is 'sint32'");
$js /= 3;
cmp_ok($js->{type}, 'eq', 'number', "/= modifies type to 'number' when appropriate");

$js = Math::JS->new(Math::JS::MAX_ULONG * 5);
cmp_ok($js->{type}, 'eq', 'number', "$js is 'number'");
$js /= 5;
cmp_ok($js->{type}, 'eq', 'uint32', "/= modifies type to 'uint32' when appropriate");
$js /= 5;
cmp_ok($js->{type}, 'eq', 'sint32', "/= modifies type to 'sint32' when appropriate");
$js /= 5;
cmp_ok($js->{type}, 'eq', 'number', "/= still modifies type to 'number' when appropriate");

done_testing();


__END__


