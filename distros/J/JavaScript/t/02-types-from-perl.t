#!perl

use Test::More tests => 20;

use strict;
use warnings;

use JavaScript;

my $rt1 = JavaScript::Runtime->new();
my $cx1 = $rt1->create_context();

$cx1->bind_function(ok => sub {
                        my ($result, $description) = @_; ok($result, $description);
                    });

$cx1->bind_function(print => sub { print STDERR @_, "\n"; });

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
    ok(v1 == undefined, "Void");
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

function test_array(v1, v2) {
    ok(v1.length == 0 &&
       v1.toString() == "", "Empty array");
    ok(v2.length == 3 &&
       v2.toString() == "1,2,3", "Array is " + v2.toString());
    
    scratch = "";
    for (x in v2) scratch += x;
    ok( scratch == '012', "Indexes are in the right order ("+ scratch + ")" );
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
}

function test_function(v1) {
    v1();
}
END_OF_CODE

$cx1->call(test_undefined => undef);
$cx1->call("test_void");
$cx1->call(test_int => -1, 0, 1, 5_000_000_000);
$cx1->call(test_float => -1.1, 0.0, 1.1, 5000000000.5);
$cx1->call(test_string => "", "foobar", $str);
$cx1->call(test_array => [], [1, 2, 3]);
$cx1->call(test_hash => {}, { a => 1, b => 2 });
$cx1->call(test_complex => { a => [1, 2, 3], b => { c => 1 } });
$cx1->call(test_function => sub { ok(1); });
