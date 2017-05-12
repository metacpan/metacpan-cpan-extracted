#!perl

use Test::More tests => 6;

use strict;
use warnings;

use Test::Exception;

use JavaScript;

my $rt1 = JavaScript::Runtime->new();

my $cx1 = $rt1->create_context();
$cx1->eval(q[
             function multiply(a, b) {
                 return a * b;
             }
         ]);
is($cx1->call("multiply", 2, 3), 6, 'Called JavaScript function via name');
throws_ok {
    $cx1->call("divide", 6, 2)
} qr/Undefined subroutine divide/, "Called non-existing function and got exception";

my $func = $cx1->eval(q{
                        /* Return a JavaScript function object */
                        multiply;
                    });

isa_ok($func, "JavaScript::Function");
is($cx1->call($func, 4, 3), 12, 'Called JavaScript function via JavaScript::Function object via $context->call');

is($func->(4, 5), 20, "Called JavaScript function via JavaScript::Function object direct invocation");

# Make sure functions aren't shared between contexts
my $cx2 = $rt1->create_context();

throws_ok {
    $cx2->call("multiply", 2, 3);
} qr/Undefined subroutine multiply/, "Functions are context-bound";
