# Test strip_tags() function : usage variations - double quoted strings
# * testing functionality of strip_tags() by giving double quoted strings as values for $str argument

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 6;

#------------------------- Test Cases ------------------------------------------
my $tests = {
    1 => "<html> \$ -> This represents the dollar sign</html><?php echo hello ?>",
    2 => "<html>\t\r\013 The quick brown fo\fx jumped over the lazy dog</p>",
    3 => "<a>This is a hyper text tag</a>",
    4 => "<? <html>hello world\\t</html>?>",
    5 => "<p>This is a paragraph</p>",
    6 => "<b>This is \ta text in bold letters\r\\s\\malong with slashes\n</b>"
};

my $results = {
    1 => '<html> $ -> This represents the dollar sign</html>',
    2 => "<html>	\r The quick brown fox jumped over the lazy dog</p>",
    3 => "<a>This is a hyper text tag</a>",
    4 => "",
    5 => "<p>This is a paragraph</p>",
    6 => '<b>This is 	a text in bold letters'."\r".'\s\malong with slashes
</b>',
};

my $quotes = "<html><a><p><b><?php";

foreach my $test_number (sort {$a <=> $b } keys %$tests) {
    is (strip_tags($tests->{$test_number}, $quotes), $results->{$test_number}, "No. ".$test_number);
}
