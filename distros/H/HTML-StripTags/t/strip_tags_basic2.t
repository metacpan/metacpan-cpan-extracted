# Test strip_tags() function : basic functionality - with all arguments

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 9;

#------------------------- Test Cases ------------------------------------------
my $tests = {
     1 => "<html>",
     2 => '<html>',
     3 => "<p>",
     4 => '<p>',
     5 => "<a>",
     6 => '<a>',
     7 => "<?php",
     8 => '<?php',
     9 => "<html><p><a><?php",
};

my $results = {
     1 => "<html>helloworldOther text</html>",
     2 => "<html>helloworldOther text</html>",
     3 => "<p>hello</p>worldOther text",
     4 => "<p>hello</p>worldOther text",
     5 => 'helloworld<a href="#fragment">Other text</a>',
     6 => 'helloworld<a href="#fragment">Other text</a>',
     7 => "helloworldOther text",
     8 => "helloworldOther text",
     9 => '<html><p>hello</p>world<a href="#fragment">Other text</a></html>',
};

my $string = "<html><p>hello</p><b>world</b><a href=\"#fragment\">Other text</a></html><?php echo hello ?>";

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($string, $tests->{$test_number}), $results->{$test_number}, "Allowed_tags: " . $tests->{$test_number});
}
