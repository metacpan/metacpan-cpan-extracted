#!perl

use Math::ScientificNotation::Util qw(sci2dec);
use Test::More 0.98;

# pass decimal notation unchanged
is(sci2dec("1"), "1");
is(sci2dec("1.23"), "1.23");

# test dies when fed a non-number

is(sci2dec("1e3")     , "1000");

is(sci2dec("1.23e20") , "123000000000000000000");
is(sci2dec("1.23e3")  , "1230");
is(sci2dec("+1.23e3") , "1230");
is(sci2dec("-1.23e3") , "-1230");
is(sci2dec("1.23e2")  , "123");
is(sci2dec("1.23e+2") , "123");
is(sci2dec("1.23e1")  , "12.3");
is(sci2dec("1.23e0")  , "1.23");
is(sci2dec("-1.23e0") , "-1.23");
is(sci2dec("1.23e-1") , "0.123");
is(sci2dec("+1.23e-1"), "0.123");
is(sci2dec("-1.23e-1"), "-0.123");
is(sci2dec("1.23e-2") , "0.0123");
is(sci2dec("1.23e-3") , "0.00123");
is(sci2dec("1.23e-20"), "0.0000000000000000000123");

is(sci2dec("12.3e-1") , "1.23");

DONE_TESTING:
done_testing;
