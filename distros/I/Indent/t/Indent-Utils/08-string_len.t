use strict;
use warnings;

use Indent::Utils qw(string_len);
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $string = '   example';
my $ret = string_len($string);
is($ret, length $string);
is($string, '   example');

# Test.
$string = "\texample";
$ret = string_len($string);
is($ret, 15);
is($string, "\texample");

# Test.
$string = "\t\texample";
$ret = string_len($string);
is($ret, 23);
is($string, "\t\texample");
$Indent::Utils::TAB_LENGTH = 2;
$ret = string_len($string);
is($ret, 11);
is($string, "\t\texample");

# Test.
$string = "\t example";
$ret = string_len($string);
is($ret, 10);
is($string, "\t example");
