#!perl
##----------------------------------------------------------------------------
## Unicode CLDR Rule-Based Number Format - t/01.custom_rules.t
##
## Custom rule descriptions exercising radix, exponent markers, >>>, fraction
## rule sets, numerator substitutions with zeros, plural patterns, the |
## operator, @noparse, rollback, Inf and NaN rules and lenient parsing.
## Expectations generated with ICU 79.1.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use File::Spec;
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Locale::Unicode::RBNF' ) || BAIL_OUT( 'Unable to load Locale::Unicode::RBNF' );
};

my $cldr = File::Spec->catdir( 't', 'cldr' );

my %rules = (
    fractions => [ 'en', "%main:\n    -x: minus >>;\n    x.x: << and >%%frac>;\n    0.x: >%%frac>;\n    0: zero; 1: one; 2: two; 3: three; 4: four; 5: five; 6: six; 7: seven; 8: eight; 9: nine;\n    10: ten; 11: eleven; 12: twelve; 13: thirteen; 20: twenty[->>]; 30: thirty[->>];\n    100: << hundred[ >>];\n%%frac:\n    2: <%main< half; 2: <%main< halves;\n    3: <%main< third; 3: <%main< thirds;\n    4: <%main< quarter; 4: <%main< quarters;\n    10: <%main< tenth; 10: <%main< tenths;\n    100: <%main< hundredth; 100: <%main< hundredths;\n" ],
    digits => [ 'en', "%main:\n    -x: minus >>;\n    x.x: << point >>;\n    x.0: << point zero;\n    0: zero; 1: one; 2: two; 3: three; 4: four; 5: five; 6: six; 7: seven; 8: eight; 9: nine;\n    10: << >>>;\n    Inf: forever;\n    NaN: nothing;\n" ],
    radix => [ 'en', "%octal:\n    0: 0; 1: 1; 2: 2; 3: 3; 4: 4; 5: 5; 6: 6; 7: 7;\n    8/8: <<>>>;\n    64/8: <<>>>;\n    512/8: <<>>>;\n    4096/8: <<>>>;\n%spaced:\n    0: zero; 1: one; 2: two; 3: three; 4: four; 5: five; 6: six; 7: seven;\n    8/8: << >>;\n    64/8: << >>;\n    512/8: << >>;\n    4096/8: << >>;\n    32768/8: << >>;\n" ],
    exponent => [ 'en', "%main:\n    0: =#,##0=;\n    100>: << hundred[ >>];\n    1000: << thousand[ >>];\n    1000000: =#,##0=;\n%alt:\n    0: =0=;\n    10: << ten[ >>];\n    100: << hundred[ >>];\n    1100>>: <%alt< hundred[ >>];\n    2000: << thousand[ >>];\n" ],
    numerator => [ 'en', "%main:\n    x.x: << point >%%frac>;\n    0.x: zero point >%%frac>;\n    0: zero; 1: one; 2: two; 3: three; 4: four; 5: five; 6: six; 7: seven; 8: eight; 9: nine;\n    10: ten; 11: eleven; 12: twelve; 20: twenty[->>]; 30: thirty[->>]; 100: << hundred[ >>];\n%%frac:\n    10: <%main<<;\n    100: <%main<<;\n    1000: <%main<<;\n" ],
    plural_orelse => [ 'en', "%main:\n    0: zero; 1: one; 2: two; 3: three; 4: four; 5: five; 6: six; 7: seven; 8: eight; 9: nine;\n    10: ten; 20: twenty[->>];\n    100: << \$(cardinal,one{hundred}other{hundreds})\$[ >>];\n    1000: << \$(cardinal,one{thousand}other{thousands})\$[ >>|s];\n%ord:\n    0: =%main=th;\n    1: =%main=st;\n    2: =%main=nd;\n    3: =%main=rd;\n    4: =%main=th;\n    20: twenty[->%ord>|ieth];\n" ],
    noparse_rollback => [ 'en', "%main:\n    0: zero; 1: one; 2: two; 3: three;\n    4: four; 5: five; 10: ten; 50: fifty[->>];\n    100: << hundred[ >>];\n    1000: << thousand[ >>];\n%hidden\@noparse:\n    0: nope; 1: =%main=;\n" ],
    apostrophe_negdouble => [ 'en', "%main:\n    -x: negative>>;\n    x.x: <<' and a half;\n    0: zero; 1: ' one; 5: ' five;\n" ],
    lenient => [ 'en', "%main:\n    0: zero; 1: one; 2: two; 3: three; 4: four; 5: five; 6: six; 7: seven; 8: eight; 9: nine;\n    10: ten; 20: twenty[->>]; 30: thirty[->>]; 90: ninety[->>];\n    100: << hundred[ >>];\n    1000: << thousand[ >>];\n" ],
    turkic => [ 'tr', "%main:\n    0: s\x{0131}f\x{0131}r; 1: bir; 2: iki;\n" ],
    nfc => [ 'de', "%main:\n    0: null; 1: \x{00E9}ins; 2: zw\x{00E9}i;\n" ],
);

my @tests = (
    [ 'fractions', 'F', '%main', 'i', '0', "zero" ],
    [ 'fractions', 'F', '%main', 'i', '1', "one" ],
    [ 'fractions', 'F', '%main', 'i', '5', "five" ],
    [ 'fractions', 'F', '%main', 'i', '12', "twelve" ],
    [ 'fractions', 'F', '%main', 'i', '123', "one hundred twenty-three" ],
    [ 'fractions', 'F', '%main', 'd', '0.5', "one half" ],
    [ 'fractions', 'F', '%main', 'd', '0.25', "one quarter" ],
    [ 'fractions', 'F', '%main', 'd', '1.75', "one and three quarters" ],
    [ 'fractions', 'F', '%main', 'd', '0.333', "one third" ],
    [ 'fractions', 'F', '%main', 'd', '2.3', "two and three tenths" ],
    [ 'fractions', 'F', '%main', 'd', '0.125', "zero halves" ],
    [ 'fractions', 'F', '%main', 'd', '3.6667', "three and two thirds" ],
    [ 'fractions', 'F', '%main', 'd', '-0.5', "minus one half" ],
    [ 'fractions', 'F', '%main', 'd', '12.5', "twelve and one half" ],
    [ 'fractions', 'F', '%main', 'd', '0.01', "one hundredth" ],
    [ 'fractions', 'F', '%main', 'd', '0.007', "zero halves" ],
    [ 'fractions', 'P', 0, "one half", '0.5', 8, -1 ],
    [ 'fractions', 'P', 0, "three quarters", '0.75', 14, -1 ],
    [ 'fractions', 'P', 0, "two and one third", '2.3333333333333335', 17, -1 ],
    [ 'fractions', 'P', 0, "zero point five", '0', 4, -1 ],
    [ 'fractions', 'P', 0, "minus one half", '-0.5', 14, -1 ],
    [ 'fractions', 'P', 1, "one half", '0.5', 8, -1 ],
    [ 'fractions', 'P', 1, "three quarters", '0.75', 14, -1 ],
    [ 'fractions', 'P', 1, "two and one third", '2.3333333333333335', 17, -1 ],
    [ 'fractions', 'P', 1, "zero point five", '0', 4, -1 ],
    [ 'fractions', 'P', 1, "minus one half", '-0.5', 14, -1 ],
    [ 'digits', 'F', '%main', 'i', '0', "zero" ],
    [ 'digits', 'F', '%main', 'i', '7', "seven" ],
    [ 'digits', 'F', '%main', 'i', '42', "four nine" ],
    [ 'digits', 'F', '%main', 'i', '1000', "one nine nine nine" ],
    [ 'digits', 'F', '%main', 'i', '1001', "one nine nine nine" ],
    [ 'digits', 'F', '%main', 'i', '123456789', "one nine nine nine nine nine nine nine nine" ],
    [ 'digits', 'F', '%main', 'd', '3.14159', "three point one four one five nine" ],
    [ 'digits', 'F', '%main', 'd', '0.0001', "zero point zero zero zero one" ],
    [ 'digits', 'F', '%main', 'd', '10.01', "one nine point zero one" ],
    [ 'digits', 'F', '%main', 'd', '1e-7', "zero point zero zero zero zero zero zero one" ],
    [ 'digits', 'F', '%main', 'd', '123.456', "one nine nine point four five six" ],
    [ 'digits', 'F', '%main', 'd', '1e15', "one nine nine nine nine nine nine nine nine nine nine nine nine nine nine nine point zero" ],
    [ 'digits', 'F', '%main', 'd', '-0.0', "zero point zero" ],
    [ 'digits', 'F', '%main', 'd', '0.1', "zero point one" ],
    [ 'digits', 'P', 0, "four two", '4', 4, -1 ],
    [ 'digits', 'P', 0, "three point one four", '3.1400000000000001', 20, -1 ],
    [ 'digits', 'P', 1, "four two", '4', 4, -1 ],
    [ 'digits', 'P', 1, "three point one four", '3.1400000000000001', 20, -1 ],
    [ 'radix', 'F', '%octal', 'i', '0', "0" ],
    [ 'radix', 'F', '%octal', 'i', '1', "1" ],
    [ 'radix', 'F', '%octal', 'i', '7', "7" ],
    [ 'radix', 'F', '%octal', 'i', '8', "17" ],
    [ 'radix', 'F', '%octal', 'i', '9', "17" ],
    [ 'radix', 'F', '%octal', 'i', '63', "77" ],
    [ 'radix', 'F', '%octal', 'i', '64', "107" ],
    [ 'radix', 'F', '%octal', 'i', '100', "147" ],
    [ 'radix', 'F', '%octal', 'i', '511', "777" ],
    [ 'radix', 'F', '%octal', 'i', '512', "1007" ],
    [ 'radix', 'F', '%octal', 'i', '4095', "7777" ],
    [ 'radix', 'F', '%octal', 'i', '32768', "170007" ],
    [ 'radix', 'F', '%octal', 'd', '9.5', "17" ],
    [ 'radix', 'F', '%octal', 'd', '64.25', "107" ],
    [ 'radix', 'F', '%spaced', 'i', '0', "zero" ],
    [ 'radix', 'F', '%spaced', 'i', '1', "one" ],
    [ 'radix', 'F', '%spaced', 'i', '7', "seven" ],
    [ 'radix', 'F', '%spaced', 'i', '8', "one zero" ],
    [ 'radix', 'F', '%spaced', 'i', '9', "one one" ],
    [ 'radix', 'F', '%spaced', 'i', '63', "seven seven" ],
    [ 'radix', 'F', '%spaced', 'i', '64', "one zero" ],
    [ 'radix', 'F', '%spaced', 'i', '100', "one four four" ],
    [ 'radix', 'F', '%spaced', 'i', '511', "seven seven seven" ],
    [ 'radix', 'F', '%spaced', 'i', '512', "one zero" ],
    [ 'radix', 'F', '%spaced', 'i', '4095', "seven seven seven seven" ],
    [ 'radix', 'F', '%spaced', 'i', '32768', "one zero" ],
    [ 'radix', 'F', '%spaced', 'd', '9.5', "one two" ],
    [ 'radix', 'F', '%spaced', 'd', '64.25', "one zero" ],
    [ 'radix', 'P', 0, "one two", '32770', 7, -1 ],
    [ 'radix', 'P', 0, "seven seven", '229383', 11, -1 ],
    [ 'radix', 'P', 1, "one two", '32770', 7, -1 ],
    [ 'radix', 'P', 1, "seven seven", '229383', 11, -1 ],
    [ 'exponent', 'F', '%main', 'i', '0', "0" ],
    [ 'exponent', 'F', '%main', 'i', '5', "5" ],
    [ 'exponent', 'F', '%main', 'i', '10', "10" ],
    [ 'exponent', 'F', '%main', 'i', '99', "99" ],
    [ 'exponent', 'F', '%main', 'i', '100', "10 hundred" ],
    [ 'exponent', 'F', '%main', 'i', '150', "15 hundred" ],
    [ 'exponent', 'F', '%main', 'i', '999', "99 hundred 9" ],
    [ 'exponent', 'F', '%main', 'i', '1000', "1 thousand" ],
    [ 'exponent', 'F', '%main', 'i', '1500', "1 thousand 50 hundred" ],
    [ 'exponent', 'F', '%main', 'i', '25000', "25 thousand" ],
    [ 'exponent', 'F', '%main', 'i', '999999', "99 hundred 9 thousand 99 hundred 9" ],
    [ 'exponent', 'F', '%main', 'd', '1500.5', "1 thousand 50 hundred 0" ],
    [ 'exponent', 'F', '%alt', 'i', '0', "0" ],
    [ 'exponent', 'F', '%alt', 'i', '5', "5" ],
    [ 'exponent', 'F', '%alt', 'i', '10', "1 ten" ],
    [ 'exponent', 'F', '%alt', 'i', '99', "9 ten 9" ],
    [ 'exponent', 'F', '%alt', 'i', '100', "1 hundred" ],
    [ 'exponent', 'F', '%alt', 'i', '150', "1 hundred 5 ten" ],
    [ 'exponent', 'F', '%alt', 'i', '999', "9 hundred 9 ten 9" ],
    [ 'exponent', 'F', '%alt', 'i', '1000', "1 ten hundred" ],
    [ 'exponent', 'F', '%alt', 'i', '1500', "1 hundred 5 ten hundred" ],
    [ 'exponent', 'F', '%alt', 'i', '25000', "2 ten 5 thousand" ],
    [ 'exponent', 'F', '%alt', 'i', '999999', "9 hundred 9 ten 9 thousand 9 hundred 9 ten 9" ],
    [ 'exponent', 'F', '%alt', 'd', '1500.5', "1 hundred 5 ten hundred 0" ],
    [ 'exponent', 'P', 0, "fifteen hundred", '0', 0, 0 ],
    [ 'exponent', 'P', 0, "two thousand", '0', 0, 0 ],
    [ 'exponent', 'P', 1, "fifteen hundred", '0', 0, 0 ],
    [ 'exponent', 'P', 1, "two thousand", '0', 0, 0 ],
    [ 'numerator', 'F', '%main', 'i', '0', "zero" ],
    [ 'numerator', 'F', '%main', 'i', '3', "three" ],
    [ 'numerator', 'F', '%main', 'd', '0.05', "zero point zero five" ],
    [ 'numerator', 'F', '%main', 'd', '0.005', "zero point zero zero five" ],
    [ 'numerator', 'F', '%main', 'd', '0.123', "zero point one hundred twenty-three" ],
    [ 'numerator', 'F', '%main', 'd', '2.007', "two point zero zero seven" ],
    [ 'numerator', 'F', '%main', 'd', '0.5', "zero point five" ],
    [ 'numerator', 'P', 0, "zero point zero five", '0.050000000000000003', 15, -1 ],
    [ 'numerator', 'P', 0, "two point zero zero seven", '2.0070000000000001', 15, -1 ],
    [ 'numerator', 'P', 1, "zero point zero five", '0.050000000000000003', 15, -1 ],
    [ 'numerator', 'P', 1, "two point zero zero seven", '2.0070000000000001', 15, -1 ],
    [ 'plural_orelse', 'F', '%main', 'i', '0', "zero" ],
    [ 'plural_orelse', 'F', '%main', 'i', '1', "one" ],
    [ 'plural_orelse', 'F', '%main', 'i', '2', "two" ],
    [ 'plural_orelse', 'F', '%main', 'i', '5', "five" ],
    [ 'plural_orelse', 'F', '%main', 'i', '21', "twenty-one" ],
    [ 'plural_orelse', 'F', '%main', 'i', '100', "one hundred" ],
    [ 'plural_orelse', 'F', '%main', 'i', '101', "one hundred one" ],
    [ 'plural_orelse', 'F', '%main', 'i', '200', "two hundreds" ],
    [ 'plural_orelse', 'F', '%main', 'i', '1000', "one thousands" ],
    [ 'plural_orelse', 'F', '%main', 'i', '2000', "two thousandss" ],
    [ 'plural_orelse', 'F', '%main', 'i', '2001', "two thousands one" ],
    [ 'plural_orelse', 'F', '%main', 'd', '1.5', "two" ],
    [ 'plural_orelse', 'F', '%main', 'd', '2.5', "three" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '0', "zeroth" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '1', "onest" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '2', "twond" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '5', "fiveth" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '21', "twenty-onest" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '100', "twentyieth" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '101', "twenty-onest" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '200', "twentyieth" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '1000', "twentyieth" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '2000', "twentyieth" ],
    [ 'plural_orelse', 'F', '%ord', 'i', '2001', "twenty-onest" ],
    [ 'plural_orelse', 'F', '%ord', 'd', '1.5', "twond" ],
    [ 'plural_orelse', 'F', '%ord', 'd', '2.5', "threerd" ],
    [ 'plural_orelse', 'P', 0, "two hundreds", '200', 12, -1 ],
    [ 'plural_orelse', 'P', 0, "one hundred", '100', 11, -1 ],
    [ 'plural_orelse', 'P', 0, "three thousands one", '3001', 19, -1 ],
    [ 'plural_orelse', 'P', 1, "two hundreds", '200', 12, -1 ],
    [ 'plural_orelse', 'P', 1, "one hundred", '100', 11, -1 ],
    [ 'plural_orelse', 'P', 1, "three thousands one", '3001', 19, -1 ],
    [ 'noparse_rollback', 'F', '%main', 'i', '0', "zero" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '1', "one" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '100', "one hundred" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '101', "one hundred one" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '200', "two hundred" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '250', "two hundred fifty" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '300', "three hundred" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '1100', "one thousand one hundred" ],
    [ 'noparse_rollback', 'F', '%main', 'i', '1200', "one thousand two hundred" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '0', "nope" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '1', "one" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '100', "one hundred" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '101', "one hundred one" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '200', "two hundred" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '250', "two hundred fifty" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '300', "three hundred" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '1100', "one thousand one hundred" ],
    [ 'noparse_rollback', 'F', '%hidden', 'i', '1200', "one thousand two hundred" ],
    [ 'noparse_rollback', 'P', 0, "two hundred", '200', 11, -1 ],
    [ 'noparse_rollback', 'P', 0, "two hundred fifty", '250', 17, -1 ],
    [ 'noparse_rollback', 'P', 0, "X", '0', 0, 0 ],
    [ 'noparse_rollback', 'P', 1, "two hundred", '200', 11, -1 ],
    [ 'noparse_rollback', 'P', 1, "two hundred fifty", '250', 17, -1 ],
    [ 'noparse_rollback', 'P', 1, "X", '0', 0, 0 ],
    [ 'apostrophe_negdouble', 'F', '%main', 'i', '-5', "negative five" ],
    [ 'apostrophe_negdouble', 'F', '%main', 'i', '5', " five" ],
    [ 'apostrophe_negdouble', 'F', '%main', 'i', '0', "zero" ],
    [ 'apostrophe_negdouble', 'F', '%main', 'd', '-1.5', "negative one' and a half" ],
    [ 'apostrophe_negdouble', 'F', '%main', 'd', '-0.25', "negativezero' and a half" ],
    [ 'apostrophe_negdouble', 'F', '%main', 'd', '1.5', " one' and a half" ],
    [ 'apostrophe_negdouble', 'P', 0, "negative five", '-5', 13, -1 ],
    [ 'apostrophe_negdouble', 'P', 0, " and a half", '0', 0, 0 ],
    [ 'apostrophe_negdouble', 'P', 1, "negative five", '-5', 13, -1 ],
    [ 'apostrophe_negdouble', 'P', 1, " and a half", '0', 0, 0 ],
    [ 'lenient', 'F', '%main', 'i', '21', "twenty-one" ],
    [ 'lenient', 'F', '%main', 'i', '99', "ninety-nine" ],
    [ 'lenient', 'F', '%main', 'i', '1234', "one thousand two hundred thirty-four" ],
    [ 'lenient', 'P', 0, "Twenty-One", '0', 0, 0 ],
    [ 'lenient', 'P', 0, "twenty one", '20', 6, -1 ],
    [ 'lenient', 'P', 0, "NINETY NINE", '0', 0, 0 ],
    [ 'lenient', 'P', 0, "one thousand, two hundred thirty-four", '1000', 12, -1 ],
    [ 'lenient', 'P', 0, "one\x{2009}thousand two\x{00AD}hundred thirty\x{2011}four", '1', 3, -1 ],
    [ 'lenient', 'P', 0, "twenty   one", '20', 6, -1 ],
    [ 'lenient', 'P', 0, "blah", '0', 0, 0 ],
    [ 'lenient', 'P', 1, "Twenty-One", '21', 10, -1 ],
    [ 'lenient', 'P', 1, "twenty one", '21', 10, -1 ],
    [ 'lenient', 'P', 1, "NINETY NINE", '99', 11, -1 ],
    [ 'lenient', 'P', 1, "one thousand, two hundred thirty-four", '1234', 37, -1 ],
    [ 'lenient', 'P', 1, "one\x{2009}thousand two\x{00AD}hundred thirty\x{2011}four", '1234', 36, -1 ],
    [ 'lenient', 'P', 1, "twenty   one", '21', 12, -1 ],
    [ 'lenient', 'P', 1, "blah", '0', 0, 0 ],
    [ 'turkic', 'F', '%main', 'i', '1', "bir" ],
    [ 'turkic', 'F', '%main', 'i', '2', "iki" ],
    [ 'turkic', 'P', 0, "\x{0130}K\x{0130}", '0', 0, 0 ],
    [ 'turkic', 'P', 0, "BIR", '0', 0, 0 ],
    [ 'turkic', 'P', 0, "B\x{0130}R", '0', 0, 0 ],
    [ 'turkic', 'P', 0, "iki", '2', 3, -1 ],
    [ 'turkic', 'P', 0, "B\x{0131}r", '0', 0, 0 ],
    [ 'turkic', 'P', 1, "\x{0130}K\x{0130}", '2', 3, -1 ],
    [ 'turkic', 'P', 1, "BIR", '0', 0, 0 ],
    [ 'turkic', 'P', 1, "B\x{0130}R", '1', 3, -1 ],
    [ 'turkic', 'P', 1, "iki", '2', 3, -1 ],
    [ 'turkic', 'P', 1, "B\x{0131}r", '0', 0, 0 ],
    [ 'nfc', 'F', '%main', 'i', '1', "\x{00E9}ins" ],
    [ 'nfc', 'F', '%main', 'i', '2', "zw\x{00E9}i" ],
    [ 'nfc', 'P', 0, "zwe\x{0301}i", '0', 0, 0 ],
    [ 'nfc', 'P', 0, "zw\x{00E9}i", '2', 4, -1 ],
    [ 'nfc', 'P', 0, "ZW\x{00C9}I", '0', 0, 0 ],
    [ 'nfc', 'P', 0, "e\x{0301}ins", '0', 0, 0 ],
    [ 'nfc', 'P', 1, "zwe\x{0301}i", '2', 5, -1 ],
    [ 'nfc', 'P', 1, "zw\x{00E9}i", '2', 4, -1 ],
    [ 'nfc', 'P', 1, "ZW\x{00C9}I", '2', 4, -1 ],
    [ 'nfc', 'P', 1, "e\x{0301}ins", '1', 5, -1 ],
);

my $fmts = {};
foreach my $name ( sort( keys( %rules ) ) )
{
    my( $loc, $desc ) = @{$rules{ $name }};
    $fmts->{ $name } = Locale::Unicode::RBNF->new( locale => $loc, cldr => $cldr, rules => $desc );
    ok( $fmts->{ $name }, "rules '$name' compile" ) || diag( Locale::Unicode::RBNF->error );
}

foreach my $t ( @tests )
{
    my( $name, $op, @args ) = @$t;
    my $fmt = $fmts->{ $name } || next;
    if( $op eq 'F' )
    {
        my( $rs, $kind, $n, $expect ) = @args;
        my $got = $kind eq 'i' ? $fmt->format_int( $n, $rs ) : $fmt->format_double( $n, $rs );
        is( $got, $expect, "$name $rs $kind $n" );
    }
    else
    {
        my( $lenient, $text, $value, $index, $error ) = @args;
        $fmt->lenient( $lenient );
        my( $v, $i, $e ) = $fmt->parse( $text );
        $v //= 0;
        my $same = ( $value eq 'NaN' ) ? ( $v != $v ) : ( abs( $v - $value ) <= 1e-9 * ( abs( $value ) + 1 ) );
        ok( $same, "$name parse (lenient=$lenient) '$text' value" ) || diag( "got $v, expected $value" );
        is( $i, $index, "$name parse (lenient=$lenient) '$text' index" );
        is( $e, $error, "$name parse (lenient=$lenient) '$text' error index" );
    }
}

done_testing();

__END__
