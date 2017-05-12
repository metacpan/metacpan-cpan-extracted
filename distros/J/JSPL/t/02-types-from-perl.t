#!perl
use Test::More tests => 62;

use strict;
use warnings;
use utf8;

use JSPL;

my $rt1 = JSPL::Runtime->new();
my $okvis;
{
my $cx1 = $rt1->create_context();

$cx1->bind_all(
    ok => \&ok,
    is => \&is,
    is_deeply => \&is_deeply,
    check => sub { 
	my $ref = shift;
	isa_ok($ref, 'HASH');
	isa_ok(JSPL::Context::current->jsvisitor($ref), 'JSPL::Visitor',
	    "Now a visitor");
    }, 
);

my $str = "x" x 40000;
$cx1->eval(<<"END_OF_CODE");

function test_undefined(v1) {
    ok(v1 == undefined, "Undefined");
}

/*
    Not really void but we need to know what happens
    when we call a function that expects arguments
    but we fail to provide any
*/
function test_void(v1) {
    ok(v1 == undefined, "undefined");
}


function test_int(v1, v2, v3, v4) {
    ok(v1 == -1, "Negative integers");
    ok(v2 == 0, "Zero integers");
    ok(v3 == 1, "Positive integers");
    ok(v4 == 5000000000, "Really big integers");
}

function test_float(v1, v2, v3, v4) {
    ok(v1 == -1.1, "Negative doubles");
    ok(v2 == 0.0, "Zero doubles");
    ok(v3 == 1.1, "Positive doubles");
    ok(v4 == 5000000000.5, "Really big doubles");
}

function test_string(v1, v2, v3) {
    ok(v1 == "", "Empty string");
    ok(v2 == "foobar", "Short string");
    ok(v3 == "$str", "Long string > 32768 chars");
}

function test_array(v1, v2, v3) {
    ok(v1.length == 0 &&
       v1.toString() == "", "Empty array");
    ok(v2.length == 3 &&
       v2.toString() == "3,2,1", "Array is " + v2.toString());
    
    scratch = "";
    for (x in v2) scratch += x;
    is(scratch, '012', "Indexes are in the right order ("+ scratch + ")" );

    ok(v2 instanceof PerlArray, "Instance of PerlArray");
    is(v2.indexOf(1), 2, "indexOf");

    v2.reverse();
    is(v2.toString(), "1,2,3", "Reverse");
    is(v2.join(":"), "1:2:3", "Joined is "+v2.join(":"));
    is_deeply(v2.slice(), [1, 2, 3], "slice");

    is(v3+"", "Blue,Zebra,Hump,Beluga", "Strings");
    is(v3.sort()+"", "Beluga,Blue,Hump,Zebra", "Sorted");
    is(v3.toSource(), "new PerlArray('Beluga','Blue','Hump','Zebra')", v3.toSource());
}

function test_hash(v1, v2) {
    var i = 0;
    for (var p in v1) {
        i++;
    }
    ok(i == 0, "Empty hash");

    i = 0;
    for (var p in v2) {
        if (p == "a" && v2[p] == 1) i++;
        if (p == "b" && v2[p] == 2) i++;
    }
    ok(i == 2, "Hash");
    ok(v2.toString(), '[object PerlHash]');
    ok(v2.toSource(), "new PerlHash('a',1,'b',2)");

    check(v2);
    
    ok(v2 instanceof PerlHash, "Instance of PerlHash");
}

function test_complex(v1) {
    var i = 0;
    for (var p in v1) {
        if (p == "a" && v1[p].toString() == "1,2,3") i++;
        if (p == "b") {
            var j = 0;
            for (var q in v1[p]) {
                if (q == "c" && v1[p][q] == 1) j++;
            }
            if (j == 1) {
                i++;
            }
        }
    }
    ok(i == 2, "Complex ok");
    ok(v1.toSource(), v1.toSource());
}

function test_function(v1, type) {
    ok(v1 instanceof PerlSub, "Instance of PerlSub");
    is(typeof v1, type);
    v1();
}

function test_other(v1, v2) {
    ok(true, "In test_other");
    ok(v1 instanceof PerlScalar, "Instance of PerlScalar");
    ok(v2 instanceof PerlScalar, "Instance of PerlScalar");
    is(v2.valueOf(), 1000, "A number");
    ok(v2+"" == "1000", "To string" );
    ok(v2 == 1000, "Automatic");
    var val = v1.valueOf();
    is(val, "string", "A simple string");
    ok(v1+"" == "string", "Automatic string");
}
END_OF_CODE

$cx1->call(test_undefined => undef);
$cx1->call("test_void");
$cx1->call(test_int => -1, 0, 1, 5_000_000_000);
$cx1->call(test_float => -1.1, 0.0, 1.1, 5000000000.5);
$cx1->call(test_string => "", "foobar", $str);
my $arr = [ qw(Blue Zebra Hump Beluga) ];
$cx1->call(test_array => [], [3, 2, 1], $arr);
is($arr->[0], 'Beluga', "Propagated");

{
    my $h = {};
    my $h2 = { a => 1, 'b' => 2 };
    ok(!JSPL::jsvisitor($h2), "Not a visitor yet");
    $cx1->call(test_hash => $h, $h2);
    ok(!JSPL::jsvisitor($h2), "Was a visitor");
    $h = undef;
    $h2 = undef;
}

$cx1->call(test_complex => { a => [1, 2, 3], b => { c => 1 } });
$cx1->call(test_function => sub { ok(1,"test function"); },
    JSPL::get_internal_version >= 185 
	? 'function' # Finally fixed
	: 'object'
);
$cx1->call(test_other => \"string", \1000);
{
    my $string = "string";
    my $number = 1000;
    $cx1->call(test_other => \($string, $number));
}

# Test a little more jsvisitor machinery
is(JSPL::jsvisitor(\&ok), $cx1->id, 'ok is a visitor');
ok(($okvis = $cx1->jsvisitor(\&ok)), "Can get its wrapper");
isa_ok($okvis, 'JSPL::Visitor');
ok($okvis->VALID, "Is valid");
}
ok(!JSPL::jsvisitor(\&ok), "But not now");
ok(!$okvis->VALID, "Visitor invalidated\n");

ok(1, "All done");
