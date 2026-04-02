use strict;
use warnings;

use Indent::Utils qw(remove_last_ws);;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $string = 'string   ';
remove_last_ws(\$string);
is($string, 'string', 'Remove multiple spaces on the end.');

# Test.
$string = "string \t \t";
remove_last_ws(\$string);
is($string, 'string', 'Remove multiple tab/space on the end.');

# Test.
$string = "  string \t \t";
remove_last_ws(\$string);
is($string, '  string', 'Remove multiple tab/space on the end and stay with spaces on the begin.');
