use strict;
use warnings;

use Indent::Utils qw(remove_first_ws);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $string = '   string';
remove_first_ws(\$string);
is($string, 'string', 'Remove multiple spaces on the begin.');

# Test.
$string = "\t \t string";
remove_first_ws(\$string);
is($string, 'string', 'Remove multiple tab/space on the begin.');

# Test.
$string = "\t \t string  ";
remove_first_ws(\$string);
is($string, 'string  ', 'Remove multiple tab/space on the begin and stay with spaces on the end.');
