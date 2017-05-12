
use Test::More 'no_plan';
use Data::Dumper;

use_ok('Math::Calculator');

isa_ok(
	my $calc = Math::Calculator->new(),
	'Math::Calculator'
);

is($calc->push(10), 1, "one element on stack after push");
is($calc->push( 5), 2, "two elements on stack after push");
is($calc->pop,      5, "popped the five off of the stack");
is($calc->top,     10, "current top of stack is 10");
is($calc->push( 5), 2, "two elements on stack after second push");
is($calc->clear,    0, "stack emptied");

is($calc->top,  undef, "empty stack");

is($calc->push(1,5),2, "multi-item push");
is($calc->add,      6, "1 + 6 = 6");

is($calc->top,      6, "top element is now 6");

is($calc->clear,    0, "stack emptied");

is($calc->push(10), 1, "one element on stack after push");
is($calc->push( 5), 2, "two elements on stack after push");
is($calc->subtract, 5, "10 - 5 = 5");

is($calc->push(10), 2, "one element on stack after push");
is($calc->multiply,50, "10 * 5 = 50");

is($calc->push(25), 2, "one element on stack after push");
is($calc->divide,   2, "50 / 25 = 2");

is($calc->clear,    0, "stack emptied");
is($calc->push(6,3),2, "push two twos, get two elements");
is($calc->divide,   2, "6 / 3 = 2");

is($calc->clear,    0, "stack emptied");
is($calc->push(3,4),2, "two elements after double push");
is($calc->modulo,   3, "3 % 4 = 3");

is($calc->clear,    0, "stack emptied");
is($calc->push(2,3),2, "two elements after double push");
is($calc->raise_to, 8, "2 ** 3 = 8");

is($calc->clear,    0, "stack emptied");
is($calc->push(8,3),2, "two elements after double push");
is($calc->root,     2, "cube_root(8) = 2");

is($calc->push(2),  2, "two elements after push");
is($calc->add,      4, "2 + 2 = 4");
is($calc->sqrt,     2, "sqrt(4) = 2");

is($calc->dupe,     2, "duplicate top value");
is($calc->dupe,     3, "duplicate top value (again)");

is($calc->push(3),  4, "four elements after push");
is($calc->twiddle,  2, "twiddle top elements, 2 is on top");
is($calc->twiddle,  3, "twiddle top elements, 3 is on top");

is_deeply(
	[ $calc->quorem ],
	[ 0, 2 ],
	"quorem of (2,3) is (0, 2)"
);

$calc->push(3);

is($calc->divmod, 2, "scalar context divmod is 3");
