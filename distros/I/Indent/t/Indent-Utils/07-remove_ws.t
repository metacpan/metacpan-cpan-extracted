use strict;
use warnings;

use Indent::Utils qw(remove_ws);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $string = 'string   ';
remove_ws(\$string);
is($string, 'string', 'Remove spaces on the end.');

# Test.
$string = "string \t \t";
remove_ws(\$string);
is($string, 'string', 'Remove tabs/spaces on the end.');

# Test.
$string = '   string';
remove_ws(\$string);
is($string, 'string', 'Remove spaces on the begin.');

# Test.
$string = "\t \t string";
remove_ws(\$string);
is($string, 'string', 'Remove tabs/spaces on the begin.');

# Test.
$string = "  string \t \t";
remove_ws(\$string);
is($string, 'string', 'Remove spaces on the begin, tabs/spaces on the end.');

# Test.
$string = " \t \t string \t \t";
remove_ws(\$string);
is($string, 'string', 'Remove tabs/spaces on the begin/end.');
