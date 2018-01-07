use strict;
use Test::More;

use Math::GF;

my $GF5 = Math::GF->new(order => 5);

my $u = $GF5->e(1);
isa_ok $u, 'Math::GF::Zn';
is $u->n, 5, 'n is fine';
is $u->v, 1, 'v is fine';

my $two = $GF5->e(2);
my $r = $u + $two;
is $r->v, 3, '1 + 2 -> 3 in GF_5';
$r = $r + $two;
is $r, $GF5->e(0), '3 + 2 -> 0 in GF_5';

my $prod = $two * $GF5->e(3);
is $prod, $u, '2 * 3 -> 1 in GF_5';

is $two->i, 3, 'inv(2) -> 3 in GF_5';
is $two->inv, $GF5->e(3), 'ditto, but on field';
is $GF5->e(4)->i, 4, 'inv(4) -> 4 in GF_5';

ok $GF5->e(3) != $two, '3 != 2 in GF_5';
is $two ** 3, $GF5->e(3), '2 ** 3 == 3 in GF_5';

is $two->stringify, "2", 'stringify, direct call';
is "$two", "2", 'stringify, via overloaded operator';

ok !(__PACKAGE__->can('Z_3')), 'sub Z_3 does not previously exist';
Math::GF->import_builder(3, name => 'Z_3');
ok __PACKAGE__->can('Z_3'), 'sub Z_3 was imported';

$r = Z_3(0) / Z_3(2);
is $r, Z_3(0), '0 / 2 -> 0 in Z_3 / GF_3';
$r = Z_3(1) / Z_3(2);
is $r, Z_3(2), '1 / 2 -> 2 in Z_3 / GF_3';
$r = Z_3(2) / Z_3(2);
is $r, Z_3(1), '2 / 2 -> 1 in Z_3 / GF_3';

my $three = $GF5->e(3);
$r = $three - $two;
is $r, $u, '3 - 2 -> 1 in GF_5';
$r = $two - $three;
is $r, $GF5->e(4), '2 - 3 -> 4 in GF_5';

done_testing();
