#!perl
use strict;
use warnings;
use Test::More;
use Test::NoWarnings ();
use lib 't/lib';
use TestPhrase 'test_phrase';

# noun conjunction noun
test_phrase 'green egg and ham', 'green eggs and ham';

# noun preposition
test_phrase 'email from', 'emails from';
test_phrase 'email to', 'emails to';

# noun preposition noun
test_phrase 'mother in law', 'mothers in law';
test_phrase 'prisoner of war', 'prisoners of war';

# noun noun
test_phrase 'book binding', 'book bindings';
test_phrase 'cable tie', 'cable ties';

# noun x2
test_phrase 'book book', 'book books';

# noun verb
test_phrase 'station visited', 'stations visited';

# adjective noun that's the same singular and plural
test_phrase 'swedish fish', 'swedish fish';

# fallback
test_phrase 'green', 'greens';

# RT#118767
test_phrase 'functionality', 'functionalities';
test_phrase 'Functionality', 'Functionalities';

Test::NoWarnings::had_no_warnings;

done_testing;

# vim:et sts=2 sw=2 tw=0:
