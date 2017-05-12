#!perl

use Test::More tests => 3;

use strict;
use warnings;

use JavaScript;

# Create a new runtime
my $rt1 = JavaScript::Runtime->new();
my $cx1 = $rt1->create_context();

$cx1->eval(q!
function test_func(a, b) {
    return a * b + (a * b);
}

not_a_func = [];
!);

is($cx1->can('test_func'), 1, "Function exists");
is($cx1->can("another_func"), 0, "Function doesn't exist");
is($cx1->can("not_a_func"), 0, "Not a function");
