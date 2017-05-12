#!perl
use strict;
use warnings;
use Test::More;
use Test::NoWarnings ();
use lib 't/lib';
use TestPhrase 'test_phrase';

# number noun
test_phrase '0 eggs', '0 eggs';
test_phrase '1 egg',  '1 egg';
test_phrase '2 eggs', '2 eggs';
test_phrase '1.5 joules', '1.5 joules';
test_phrase '2.4E4 electron-volts', '2.4E4 electron-volts';

# all other combinations with numbers
test_phrase '1 email from', '1 email from';
test_phrase '2 emails from', '2 emails from';
test_phrase '1 mother in law', '1 mother in law';
test_phrase '2 mothers in law', '2 mothers in law';
test_phrase '1 book binding', '1 book binding';
test_phrase '2 book bindings', '2 book bindings';
test_phrase '1 book book', '1 book book';
test_phrase '2 book books', '2 book books';
test_phrase '1 station visited', '1 station visited';
test_phrase '2 stations visited', '2 stations visited';
test_phrase '1 swedish fish', '1 swedish fish';
test_phrase '2 swedish fish', '2 swedish fish';
test_phrase '1 green', '1 green';
test_phrase '2 greens', '2 greens';

# ASCII fractions
test_phrase '1 1/2 joules', '1 1/2 joules';
test_phrase '1 and 1/2 joules', '1 and 1/2 joules';
test_phrase '1 and a half joules', '1 and a half joules';
test_phrase '1 and one half joules', '1 and one half joules';
test_phrase 'one and one half joules', 'one and one half joules';

# TODO Unicode fractions

# numbers as words

test_phrase 'zero eggs', 'zero eggs';
test_phrase 'one egg', 'one egg';
test_phrase 'the one egg', 'the one egg';
test_phrase 'two eggs', 'two eggs';
test_phrase 'the two eggs', 'the two eggs';
test_phrase 'the twenty two eggs', 'the twenty two eggs';
test_phrase 'one email from', 'one email from';
test_phrase 'the one email from', 'the one email from';
test_phrase 'two emails from', 'two emails from';
test_phrase 'one mother in law', 'one mother in law';
test_phrase 'the one mother in law', 'the one mother in law';
test_phrase 'two mothers in law', 'two mothers in law';
test_phrase 'one book binding', 'one book binding';
test_phrase 'the one book binding', 'the one book binding';
test_phrase 'two book bindings', 'two book bindings';
test_phrase 'one book book', 'one book book';
test_phrase 'the one book book', 'the one book book';
test_phrase 'two book books', 'two book books';
test_phrase 'one station visited', 'one station visited';
test_phrase 'the one station visited', 'the one station visited';
test_phrase 'two stations visited', 'two stations visited';
test_phrase 'one swedish fish', 'one swedish fish';
test_phrase 'the one swedish fish', 'the one swedish fish';
test_phrase 'two swedish fish', 'two swedish fish';
test_phrase 'one green', 'one green';
test_phrase 'the one green', 'the one green';
test_phrase 'two greens', 'two greens';

# numbers by themselves

test_phrase 'the 1', 'the 1s';
test_phrase 'the 2', 'the 2s';
test_phrase '1', '1s';
test_phrase '2', '2s';
test_phrase 'the one', 'the ones';
test_phrase 'the two', 'the twos';
test_phrase 'one', 'ones';
test_phrase 'two', 'twos';

# ordinal numbers

test_phrase '1st release', '1st releases';
test_phrase 'first release', 'first releases';
test_phrase 'second trip', 'second trips';
test_phrase 'twenty third egg', 'twenty third eggs';
test_phrase '2nd car', '2nd cars';

Test::NoWarnings::had_no_warnings;

done_testing;
