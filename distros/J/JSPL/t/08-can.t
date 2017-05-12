#!perl

use Test::More tests => 14;

use strict;
use warnings;

use JSPL;

# Create a new runtime
my $rt1 = JSPL::Runtime->new();
my $cx1 = $rt1->create_context();

$cx1->eval(q!
    function test_func(a, b) {
	return a * b;
    }

    not_a_func = [];
!);

$cx1->bind_all(
    foo => sub {},
    bar => {},
    baz => 'foo'
);

ok((my $fun = $cx1->can('test_func')),	"Function exists");
isa_ok($fun, "JSPL::Function", "And");
is($cx1->can($fun), $fun, "The same");
is($fun->(2, 3), 6, "Can be called");
ok(!$cx1->can("another_func"),	"Function doesn't exist");
ok(!$cx1->can("not_a_func"),	"Not a function");
SKIP: {
    skip "Not in this SM", 3 unless JSPL::get_internal_version >= 185;
    ok($fun = $cx1->can("foo"), "A perl func is a function");
    isa_ok($fun, 'CODE');
    is($cx1->can($fun), $fun, "The same");
}
ok(!$cx1->can("bar"),	"Not a function");
ok(!$cx1->can("baz"),	"Not a function");
ok(!$cx1->can(1),	"Not a function");
ok(!$cx1->can([]),	"Not a function");
ok(!$cx1->can(sub{}),	"But not in context");
