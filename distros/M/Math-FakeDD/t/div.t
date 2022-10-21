
use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

cmp_ok(dd_div('1.3', Math::FakeDD->new('9.1')), '!=',
       dd_div(Math::FakeDD->new('9.1'), '1.3'), '1: no commutativity');

cmp_ok('1.3' / Math::FakeDD->new('9.1'), '!=',
       Math::FakeDD->new('9.1') / '1.3', '2: no commutativity');

cmp_ok(dd_div('1.3', Math::FakeDD->new('9.1')), '==',
       '1.3' / Math::FakeDD->new('9.1'), "1: overloading '/' agrees with dd_div()");
cmp_ok(dd_div(Math::FakeDD->new('9.1'), '1.3'), '==',
       Math::FakeDD->new('9.1') / '1.3', "2: overloading '/' agrees with dd_div()");

my $obj1 = Math::FakeDD->new(8);
my $obj2 = Math::FakeDD->new(0.125);
my $obj3 = dd_div($obj1, $obj2);
my $obj4 = $obj1 / $obj2;

cmp_ok(dd_div(8, 0.125), '=='   , $obj1 / $obj2, "1: divisions match");
cmp_ok(Math::FakeDD->new(64), '==', $obj3      , "2: divisions match");
cmp_ok($obj4, '=='             , $obj3         , "3: divisions match");

$obj3 /= '0.125';
$obj4 /= $obj2;
cmp_ok($obj3, '==', $obj4, '1: /= ok');
dd_div_eq($obj3, '0.125');
cmp_ok($obj3, '==', Math::FakeDD->new(4096), '2: /= ok');

done_testing();

