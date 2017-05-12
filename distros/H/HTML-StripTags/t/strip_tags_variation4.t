# Test strip_tags() function : usage variations - invalid values for 'str' and valid 'allowable_tags'
# * testing functionality of strip_tags() by giving invalid values for $str and valid values for $allowable_tags argument

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 12;

#------------------------- Test Cases ------------------------------------------
my $tests = {
     1 => "<abc>hello</abc> \t\tworld... <ppp>strip_tags_test</ppp>",
     2 => '<abc>hello</abc> \t\tworld... <ppp>strip_tags_test</ppp>',
     3 => "<%?php hello\t world?%>",
     4 => '<%?php hello\t world?%>',
     5 => "<<htmL>>hello<</htmL>>",
     6 => '<<htmL>>hello<</htmL>>',
     7 => "<a.>HtMl text</.a>",
     8 => '<a.>HtMl text</.a>',
     9 => "<nnn>I am not a valid html text</nnn>",
    10 => '<nnn>I am not a valid html text</nnn>',
    11 => "<nnn>I am a quoted (\") string with special chars like \$,\!,\@,\%,\&</nnn>",
    12 => '<nnn>I am a quoted (\") string with special chars like \$,\!,\@,\%,\&</nnn>',
};

my $results = {
     1 => "hello 		world... strip_tags_test",
     2 => 'hello \t\tworld... strip_tags_test',
     3 => "",
     4 => "",
     5 => "<htmL>hello</htmL>",
     6 => "<htmL>hello</htmL>",
     7 => "HtMl text",
     8 => "HtMl text",
     9 => "I am not a valid html text",
    10 => "I am not a valid html text",
    11 => 'I am a quoted (") string with special chars like $,!,@,%,&',
    12 => 'I am a quoted (\") string with special chars like \$,\!,\@,\%,\&',
};

my $allowed_tags = "<p><a><?php<html>";

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($tests->{$test_number}, $allowed_tags), $results->{$test_number}, $test_number.": ".$tests->{$test_number});
}
