
use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

cmp_ok($Math::FakeDD::VERSION, '==', 0.01, "Version number is correct");

my $obj = Math::FakeDD->new();

dd_assign($obj, '1.3');

cmp_ok("$obj", 'eq', "[1.3 -4.4408920985006264e-17]", "'1.3' assigns and stringifies correctly");

done_testing();
