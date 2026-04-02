use strict;
use warnings;

use Indent::Utils qw(string_len);
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $string = '   example';
my $ret = string_len($string);
is($ret, length $string, 'Count characters in string (spaces, string).');
is($string, '   example', 'Compare string (spaces, string).');

# Test.
$string = "\texample";
$ret = string_len($string);
is($ret, 15, 'Count characters in string, tab is 8 characters (tab, string).');
is($string, "\texample", 'Compare string (tab, string).');

# Test.
$string = "\t\texample";
$ret = string_len($string);
is($ret, 23, 'Count characters in string, tab is 8 characters (two tabs, string).');
is($string, "\t\texample", 'Compare string (two tabs, string).');
$Indent::Utils::TAB_LENGTH = 2;
$ret = string_len($string);
is($ret, 11, 'Count characters in string, tab is 2 characters (two tabs, string).');
is($string, "\t\texample", 'Compare string (two tabs, string).');

# Test.
$string = "\t example";
$ret = string_len($string);
is($ret, 10, 'Count characters in string, tab is 2 characters (tab, space, string).');
is($string, "\t example", 'Compare string (tab, space, string).');
