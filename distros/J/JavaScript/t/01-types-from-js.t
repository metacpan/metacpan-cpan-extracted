#!perl

use Test::More tests => 20;

use strict;
use warnings;

use JavaScript;

my $rt1 = JavaScript::Runtime->new();
my $cx1 = $rt1->create_context();

# Undefined and void.. kinda same thing
is($cx1->eval("undefined;"), undef, "Undefined");
is($cx1->eval("function foo() {} foo();"), undef, "Void");

# Integers
is($cx1->eval("-1;"), -1, "Negative integers");
is($cx1->eval("0;"), 0, "Zero integers");
is($cx1->eval("1;"), 1, "Positive integers");
is($cx1->eval("5000000000;"), 5_000_000_000, "Really big integers");

# Doubles
is($cx1->eval("-1.1;"), -1.1, "Negative doubles");
is($cx1->eval("0.0;"), 0.0, "Zero doubles");
is($cx1->eval("1.1;"), 1.1, "Positive doubles");
is($cx1->eval("5000000000.5;"), 5000000000.5, "Really big doubles");

# Strings
is($cx1->eval(q{"";}), "", "Empty string");
is($cx1->eval(q{"foobar";}), "foobar", "Short string");
my $str = "A" x 40000;
is($cx1->eval(qq{"$str";}), $str, "Long string > 32768 chars");

# Booleans
ok($cx1->eval("1 == 1;"), "True");
ok(!$cx1->eval("1 == 0;"), "False");

# Arrays
is_deeply($cx1->eval("v = []; v;"), [], "Empty array");
is_deeply($cx1->eval("v = [1, 2, 3]; v;"), [1, 2, 3], "Array");

# Anonymous objects
is_deeply($cx1->eval("v = {}; v;"), {}, "Empty hash");
is_deeply($cx1->eval("v = {a: 1, b: 2}; v;"), { a => 1, b => 2}, "Hash");

# Complex objects
is_deeply($cx1->eval("v = {a: [1,2,3], b: { c: 1 }}; v;"), { a => [1, 2, 3],
                                                             b => { c => 1 }
                                                        }, "Complex");
