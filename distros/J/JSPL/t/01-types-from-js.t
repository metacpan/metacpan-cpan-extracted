#!perl
use Test::More tests => 107;
use strict;

use JSPL qw(:primitives);

my $LoDo;
use Config;
BEGIN {
    if ($Config{uselongdouble} &&
	$Config{doublesize} != $Config{longdblsize})
    {
	$LoDo = 1; # Expect some precision lost
    }
}
use warnings;

my $rt1 = JSPL::Runtime->new();
{
my $cx1 = $rt1->create_context();

# Get global object
isa_ok($cx1->get_global, "JSPL::Object", "Global Object");

# Undefined 
is($cx1->eval("undefined;"), undef, "Undefined");
is($cx1->eval("function foo() {} foo();"), undef, "Undefined");

# Integers
is($cx1->eval("-1;"), -1, "Negative integers");
is($cx1->eval("0;"), 0, "Zero integers");
is($cx1->eval("1;"), 1, "Positive integers");
is($cx1->eval("5000000000;"), 5_000_000_000, "Really big integers");

# Doubles
is($cx1->eval("0.0;"), 0.0, "Zero doubles");
if($LoDo) {
    is(sprintf('%.6f', $cx1->eval("1.1;")), sprintf('%.6f', 1.1), "Positive doubles");
    is(sprintf('%.6f', $cx1->eval("-1.1;")), sprintf('%.6f', -1.1), "Negative doubles");
    ok(!JSPL::exact_doubles(), "Precision lost detectable");
} else {
    cmp_ok($cx1->eval("1.1;"), '==', 1.1, "Positive doubles");
    cmp_ok($cx1->eval("-1.1;"), '==', -1.1, "Negative doubles");
    ok(JSPL::exact_doubles(), "Exact doubles");
}
cmp_ok($cx1->eval("5000000000.5;"),'==', 5000000000.5, "Really big doubles");

# Strings
is($cx1->eval(q{ ""; }), "", "Empty string");
is($cx1->eval(q{ "foobar"; }), "foobar", "Short string");
my $str = "A" x 40000;
is($cx1->eval(qq{"$str";}), $str, "Long string > 32768 chars");

# Booleans
{
    ok(my $t1 = $cx1->eval("1 == 1;"), "True");
    isa_ok($t1, "JSPL::Boolean", "Wrapped true");
    pass("Boolean true works") if $t1;

    my $f1 = $cx1->eval("1 == 0;");
    ok(!$f1 , "False");
    isa_ok($f1, "JSPL::Boolean", "Wrapped false");
    pass("Boolean false works") unless $f1;

    ok(my $t2 = $cx1->eval("true;"), "True");
    my $f2 = $cx1->eval("false;");
    ok(!$f2, "False");
    is($t1, $t2, "True is True");
    ok($t1 eq $t2,  "T eq T");
    ok($t1 == $t2,  "T == T");
    ok($t1 eq JS_TRUE, "The constant TRUE");
    pass("True") if $t1 && $t2;

    is($f1, $f2, "False is False");
    ok($f1 eq $f2,  "F eq F");
    ok($f1 == $f2,  "F == F");
    ok($f1 eq JS_FALSE, "The constant FALSE");
    pass("False") unless $f1 || $f2;

    isnt($t1, $f1, "T != F");
}

# Anonymous objects
{
    my $obj = $cx1->eval("({});");
    ok(defined($obj), "Empty Defined");
    isa_ok($obj, 'HASH', "An object");
    isa_ok(tied(%$obj), 'JSPL::Object', "Boxed");

    $obj = $cx1->eval("v1 = {}; v1;");
    ok(defined($obj), "V is defined");
    isa_ok($obj, 'HASH', "Another object");
    isa_ok(tied(%$obj), 'JSPL::Object', "Boxed");
    my $obj2 = $cx1->eval("v1;");
    ok(defined($obj2), "V is defined");
    isa_ok($obj2, 'HASH', "Another copy");
    isa_ok(tied(%$obj), 'JSPL::Object', "Boxed");
    is(ref($obj),ref($obj2),"The same object");
    is(ref(tied %$obj),ref(tied %$obj2),"Internally the same object");
    $obj = undef;
    ok(!defined($obj),"Undefined");
    $obj2 = undef;
    ok(!defined($obj2), "Undefined");
    $cx1->eval('delete v1;');
}

{
    my $hash = $cx1->eval("v = {a: 1, b: 2, c: 'bar'}; v;");
    ok(defined($hash), "Defined");
    is_deeply($hash, { a => 1, b => 2, c => 'bar'}, "Deeply Hash");
    is($hash->{c}, 'bar', 'Get works');

    # Use eval to get an object ref
    $hash = $cx1->eval("v;");
    ok(defined($hash), "v defined via eval");
    isa_ok(tied(%{$hash}), 'JSPL::Object', "Tied JS object");
    my $clone = $hash;
    isa_ok($clone, 'HASH', "Correct type");
    isa_ok(tied(%{$clone}), 'JSPL::Object', "Cloned tied");
    is(ref($hash),ref($clone),"The same object");
    is_deeply($clone,
	{ a => 1, b => 2, c => 'bar'}, "Compare hash");
    is($cx1->eval("v.c"), 'bar', 'Property is in it');
    is($hash->{b},2, 'Property get works');
    ok($hash->{a} = $hash->{c}, "Try store");
    is($hash->{a}, 'bar', "Store works");
    is($cx1->eval("v.a"), 'bar', "Visible via eval");
    is_deeply([sort keys %$hash],[qw(a b c)], "keys works");
    is(scalar(keys %$hash), 3, "scalar key work");
    ok($hash->{b} = $hash, "Try create recursive");
    ok(defined($hash->{b}), "Defined");
    isa_ok($hash->{b}, 'HASH', "A hash");
    isa_ok(tied(%{$hash->{b}}), 'JSPL::Object', "JS Object again");
    isa_ok($cx1->eval("v.b"), 'HASH', "The same");
    is($clone->{c}, 'bar', "clone alive");
    $hash->{a} = 'baz';
    is($clone->{a}, 'baz', "clone changed");
    # Test methods
    is(tied(%{$hash})->toString, '[object Object]', "Call method toString");
    is(eval {tied(%{$hash})->not_a_method}, undef, "Call nomethod");
    like($@, qr/Undefined subroutine/, 'Set error')
}

# Arrays
{
    isa_ok($cx1->eval("v = []; v;"), 'ARRAY', "Empty array");
    is_deeply($cx1->eval("v;"), [], "Empty array");
    is_deeply($cx1->eval("v = ['one', 2, 3, 'foo']; v;"), ['one', 2, 3, 'foo'], "Array");

    my $arr = $cx1->eval("([])");
    ok(defined($arr), "Defined");
    isa_ok($arr, 'ARRAY', "A simple array");
    my $jsobj = tied(@{$arr});
    isa_ok($jsobj, 'JSPL::Array', "Is a JS Array");
    isa_ok($jsobj, 'JSPL::Object', "Object too");
    my $len = $jsobj->length;
    is($len, 0, 'Is empty');
    is(scalar(@{$arr}), 0, 'Using scalar(@$arr)');
    $arr = $cx1->eval('v;');
    ok(defined($arr), "Defined");
    isa_ok($arr, 'ARRAY', "A simple array");
    $jsobj = tied(@{$arr});
    isa_ok($jsobj, 'JSPL::Array', "Is a JS Array");
    isa_ok($jsobj, 'JSPL::Object', "Object too");
    is_deeply($arr, ['one', 2, 3, 'foo'], "Flaten");
    $len = $jsobj->length;
    is($len, 4, 'Has elements (4)');
    is(scalar(@$arr), 4, 'Using scalar(@$arr)');
    is($arr->[3], 'foo', 'Can get elem');
    is($jsobj->toString(), 'one,2,3,foo', 'Can call method');
    is($jsobj->pop, 'foo', 'Method pop works');
    is(pop(@$arr), 3, 'Perl pop works');
    is(shift(@$arr), 'one', 'Direct shift works');
    is($jsobj->length, 1, 'Only one left');
}

# Complex objects
{
    my $obj = $cx1->eval("v = {a: [1,2,3], b: { c: 1 }}; v;");
    ok(defined($obj),"Defined complex");
    isa_ok($obj, 'HASH', "Is hash");
    isa_ok(tied(%{$obj}), 'JSPL::Object', 'Is object');
    my $a = $obj->{a};
    ok(defined($a), "Defined a");
    isa_ok($a, 'ARRAY', 'Is');
    is($a->[1], 2, "Can access data");
    is_deeply($obj, {a => [1, 2, 3], b => { c => 1 }}, "Complex");
    is_deeply($a, [1, 2, 3], "Complex");
}

# Test Global
{
    ok((my $glb = $cx1->get_global), "Get the global object");
    is_deeply([sort keys %$glb], ['foo', 'v'], "What has created");
    delete $glb->{v};
    is($cx1->eval('typeof v'), 'undefined', "Gone");
    for(0 .. 5) {
	my $m = $cx1->eval('Math');
	$m = undef;
    }
}

}
ok(1, "all done, clean");

