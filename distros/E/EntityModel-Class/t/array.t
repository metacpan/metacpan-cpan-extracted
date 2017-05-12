use strict;
use warnings;
use 5.10.0;
use FindBin;
use lib "$FindBin::Bin/..";

use Test::More tests => 21;
use Test::Deep;
use EntityModel::Array;

my @data = qw(
	first
	second
	third
);

ok(my $x = new EntityModel::Array::(\@data), 'create from array');
is($x->count, 3, 'count is correct');
cmp_deeply([ $x->list ], \@data, 'list is correct');

my $hadChange = 0;
$x = new_ok('EntityModel::Array' => [\@data, onchange => [ sub { $hadChange += ($_[0] eq 'add') ? 1 : -1; } ] ]);
is($hadChange, 0, 'starts at zero');
ok($x->push('test'), 'push value');
is($hadChange, 1, 'now 1');
ok($x->push('test', 'this'), 'push two values');
is($hadChange, 3, 'now 3');
ok($x->pop, 'pop value');
is($hadChange, 2, 'now 2');
ok(my $y = EntityModel::Array->new([qw(a b c d e)]), 'create new array');
is($y->count, 5, 'have 5 to start with');
is($y->remove('b'), $y, 'removing one value returns $self');
is($y->count, 4, 'count is decreased');
is($y->join(' '), 'a c d e', 'contents match expected after removal by value');
is($y->remove(sub { $_[0] eq 'd' }), $y, 'removing one value by coderef returns $self');
is($y->count, 3, 'count goes down further');
is($y->join(' '), 'a c e', 'contents match expected after removal by coderef');
is($y->clear, $y, 'returns $self after clear');
is($y->count, 0, 'zero elements after clear');

