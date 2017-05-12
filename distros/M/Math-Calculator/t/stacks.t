
use Test::More 'no_plan';
use Data::Dumper;

use_ok('Math::Calculator');

isa_ok(
	my $calc = Math::Calculator->new(),
	'Math::Calculator'
);

is($calc->current_stack,            "default", "start on default stack");
is($calc->push(10,20,30),                   3, "three items on default stack");


is($calc->current_stack("two"),         "two", "switch to stack two");
is($calc->push(15,25,35),                   3, "three items on stack two");
is($calc->push_to(default => (1,2)),        5, "three items on default stack");
is($calc->add,                             60, "25 + 35 = 60");

is_deeply(
	$calc->stack("default"),
	[ 10, 20, 30, 1, 2 ],
	"access default stack"
);

is_deeply($calc->stack("two"), [ 15, 60 ], "access stack two");

is_deeply(
	[ $calc->pop_from(default => 2) ],
	[ 1, 2 ],
	"pop two elements from default stack"
);

is($calc->current_stack("default"), "default", "switch to default stack");
is($calc->add,                             50, "20 + 30 = 50");

# so, now it's (10,50) and (15,60)
is($calc->from_to('default', 'two'), 3, "from_to to push to two");

is_deeply($calc->stack("default"), [ 10         ], "default stack: 10");
is_deeply($calc->stack("two"),     [ 15, 60, 50 ], "stack two    : 15, 60, 50");

is($calc->from_to('two', 'default', 2), 3, "from_to to push to two");

is_deeply($calc->stack("default"), [ 10, 60, 50 ], "default stack: 10, 60, 50");
is_deeply($calc->stack("two"),     [ 15         ], "stack two    : 15");

is($calc->current_stack("no go!"),  "default", "don't switch to invalid stack");
