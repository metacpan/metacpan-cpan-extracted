#!perl

use Test::More tests => 33;

use strict;
use warnings;

use Test::Exception;

use JSPL;

my $rt1 = JSPL::Runtime->new();

{
my $cx1 = $rt1->create_context();
$cx1->eval(q[
             function multiply(a, b) {
                 return a * b;
             }
	     multiply.attr = 'hi';
         ]);
is($cx1->call("multiply", 2, 3), 6, 'Called javascript function via name');

throws_ok {
    $cx1->call("divide", 6, 2)
} qr/Undefined subroutine divide/, "Called non-existing function and got exception";

my $func = $cx1->eval(q{
                        /* Return a javascript function object */
                        multiply;
                    });

isa_ok($func, "JSPL::Function");
isa_ok($func, "JSPL::Object", "Also");
is($cx1->call($func, 4, 3), 12, 'Call via JSPL::Function object via $context->call');

is($func->(4, 5), 20, "Call via JSPL::Function object direct invocation");

is($func->call(undef, 6, 3), 18, 'Call via call method');

is($func->apply(undef, [7, 4]), 28, "Called via apply method");

is($func->{attr}, 'hi', "Has properties");

{
    ok(my $obj = \%{$func},"Can get it as an object");
    isa_ok($obj, 'HASH');
    isa_ok(tied(%$obj),"JSPL::Function");
    is(ref($func),ref(tied %$obj), "Same reference");

    is($obj->{attr}, 'hi', "Object usable");
    is($obj->{name}, 'multiply', "My name is 'multiply'");
    is($obj->{'length'}, 2, "Expect two arguments");
    ok(my $proto = $func->prototype, "Has a prototype");
    isa_ok($proto, 'JSPL::Object', "The proto");
    { 
	local $cx1->{AutoTie} = 0;
	is($proto, $obj->{'prototype'}, "proto is here too");
    }
    #only one reference
}

is($func->{constructor}, $cx1->get_global->{'Function'}, "Is a function");
is($func->{constructor}{name}, 'Function', " as expected");
is($func->{__proto__}, $func->{constructor}{'prototype'}, " has a __proto__");

ok($func->toString(), "As string is '".$func->toString()."'");
ok($func->toSource(), "Source is '". $func->toSource(). "'");

$cx1->get_global->{'mult'} = $func;
is($cx1->eval(q{ typeof mult }), 'function',  "Can create a clone");
is($cx1->call(mult => 2, 3), 6, "Clone called");
$cx1->get_global->{'mult'} = undef;
is($cx1->eval(q{ typeof mult }), 'undefined', "Clone gone");
throws_ok {
    $cx1->call(mult => 2, 3);
} qr/Undefined subroutine mult/, "Can't be called";

{
    # Make sure functions aren't shared between contexts
    my $cx2 = $rt1->create_context();
    throws_ok {
	$cx2->call("multiply", 2, 3);
    } qr/Undefined subroutine multiply/, "Functions are context-bound";
}

$cx1->get_global->{'multiply'} = undef;

throws_ok { $cx1->call(multiply => 2, 3); } qr/Undefined/, "Deleted";

$cx1->get_global->{'multiply'} = $func;
is($cx1->call(multiply => 2, 3), 6, "Reinstalled");
undef $func;
is($cx1->call(multiply => 2, 3), 6, "Alive");

}


ok(1, "All done, clean");
