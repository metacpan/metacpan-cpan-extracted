# Test strip_tags() function : usage variations - valid value for 'str' and invalid values for 'allowable_tags'
# * testing functionality of strip_tags() by giving valid value for $str and invalid values for $allowable_tags argument

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 8;

#------------------------- Test Cases ------------------------------------------
my $string = "<html>hello</html> \tworld... <p>strip_tags_test\013\f</p><?php hello\013 wo\rrld?>";

my $quotes = {
    1 => "<nnn>",
    2 => '<nnn>',
    3 => "<abc>",
    4 => '<abc>',
    5 => "<%?php",
    6 => '<%?php',
    7 => "<<html>>",
    8 => '<<html>>'
};

my $results = {
    1 => "hello 	world... strip_tags_test",
    2 => "hello 	world... strip_tags_test",
    3 => "hello 	world... strip_tags_test",
    4 => "hello 	world... strip_tags_test",
    5 => "hello 	world... strip_tags_test",
    6 => "hello 	world... strip_tags_test",
    7 => "<html>hello</html> 	world... strip_tags_test",
    8 => "<html>hello</html> 	world... strip_tags_test"
};

foreach my $test_number (sort {$a <=> $b } keys %$quotes) {
    is (strip_tags($string, $quotes->{$test_number}), $results->{$test_number}, $quotes->{$test_number});
}
