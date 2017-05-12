#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Fatal 'exception';

use Lingua::EN::Number::IsOrdinal ();

use lib 't/lib';
use TestOrdinal qw/is_ordinal is_not_ordinal/;

# ordinal numbers as words

is_ordinal 'first';
is_ordinal ' second	';
is_ordinal 'one hundred twenty third';
is_ordinal 'two hundred eleventh';

# ordinal numbers as digits

is_ordinal ' 1st ';
is_ordinal '2nd';
is_ordinal '5643rd';

# cardinal numbers as words

is_not_ordinal 'one';
is_not_ordinal 'two';
is_not_ordinal 'three';
is_not_ordinal 'one thousand one hundred and twenty two';

# cardinal numbers as digits

is_not_ordinal '1.005';
is_not_ordinal '10e6';
is_not_ordinal '10E6';
is_not_ordinal '1';
is_not_ordinal '2';
is_not_ordinal '3';
is_not_ordinal '234254345';

# checking for numbers

like(
    exception { Lingua::EN::Number::IsOrdinal::is_ordinal('cheese') },
    qr/not a number/,
    'throws on not a number',
);

done_testing;
