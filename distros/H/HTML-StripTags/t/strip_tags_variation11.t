# Test strip_tags() function : obscure values within attributes

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 4;

#------------------------- Test Cases ------------------------------------------
my $tests = {
    1 => 'hello <img title="<"> world',
    2 => 'hello <img title=">"> world',
    3 => 'hello <img title=">_<"> world',
    4 => "hello <img title='>_<'> world"
};

my $results = {
    1 => "hello  world",
    2 => "hello  world",
    3 => "hello  world",
    4 => "hello  world"
};

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($tests->{$test_number}), $results->{$test_number}, $tests->{$test_number});
}
