use strict;
use warnings;
use Test::More;
use Test::NoWarnings ();
use lib 't/lib';
use TestPhrase 'test_phrase';

# some tests for odd cases in DBIx::Class::Schema::Loader

test_phrase 'loader test25 from', 'loader test25s from';

test_phrase 'belongs to', 'belongs to';

Test::NoWarnings::had_no_warnings;

done_testing;

# vim:et sts=2 sw=2 tw=0:
