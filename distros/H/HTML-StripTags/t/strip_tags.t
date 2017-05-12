# Test strip_tags() function : usage variations - heredoc strings
# * testing functionality of strip_tags() by giving heredoc strings as values for $str argument

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 7;

#------------------------- Test Cases ------------------------------------------
my $tests = {
    1 => 'NEAT <? cool < blah ?> STUFF',
    2 => 'NEAT <? cool > blah ?> STUFF',
    3 => 'NEAT <!-- cool < blah --> STUFF',
    4 => 'NEAT <!-- cool > blah --> STUFF',
    5 => 'NEAT <? echo \"\\\"\"?> STUFF',
    6 => 'NEAT <? echo \'\\\'\'?> STUFF',
    7 => 'TESTS ?!!?!?!!!?!!',
};

my $results = {
    1 => 'NEAT  STUFF',
    2 => 'NEAT  STUFF',
    3 => 'NEAT  STUFF',
    4 => 'NEAT  STUFF',
    5 => 'NEAT  STUFF',
    6 => 'NEAT  STUFF',
    7 => 'TESTS ?!!?!?!!!?!!',
};

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($tests->{$test_number}), $results->{$test_number}, $tests->{$test_number});
}
