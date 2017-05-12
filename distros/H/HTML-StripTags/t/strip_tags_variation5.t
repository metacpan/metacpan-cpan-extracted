# Test strip_tags() function : usage variations - heredoc strings
# * testing functionality of strip_tags() by giving heredoc strings as values for $str argument

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 6;

#------------------------- Test Cases ------------------------------------------
my $tests = {};

# null here doc string
$tests->{1} = <<'EOT'
EOT
;
# heredoc string with blank line
$tests->{2} = <<'EOT'

EOT
;
# here doc with multiline string
$tests->{3} = <<'EOT'
<html>hello world</html>
<p>13 &lt; 25</p>
<?php 1111 &amp; 0000 = 0000 ?>
<b>This is a double quoted string</b>
EOT
;
# here doc with diferent whitespaces (Perl uses \013 instead of \v)
$tests->{4} = <<EOT
<html>hello\r world\t
1111\t\t != 2222\013\013</html>
<? heredoc\ndouble quoted string. with\013different\fwhite\013spaces ?>
EOT
;
# here doc with numeric values
$tests->{5} = <<EOT
<html>11 < 12. 123 >22</html>
<p>string</p> 1111\t <b>0000\t = 0000\n</b>
EOT
;
# heredoc with quote chars & slash
$tests->{6} = <<'EOT'
<html>This's a string with quotes:</html>
"strings in double quote";
'strings in single quote';
<html>this\line is single quoted /with\slashes </html>
EOT
;


# result
# NOTE: heredoc in Perl adds one newline at the end, C doesn't
my $results = {};

$results->{1} = "";
$results->{2} = "
";
$results->{3} = "<html>hello world</html>
13 &lt; 25

This is a double quoted string
";
$results->{4} = "<html>hello\r world	
1111		 != 2222</html>

";
$results->{5} = "<html>11 < 12. 123 >22</html>
string 1111	 0000	 = 0000

";
$results->{6} = '<html>This\'s a string with quotes:</html>
"strings in double quote";
\'strings in single quote\';
<html>this\line is single quoted /with\slashes </html>
';

# initialize the second argument
my $quotes = "<html><a><?php";

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($tests->{$test_number}, $quotes), $results->{$test_number}, "No. ".$test_number);
}
