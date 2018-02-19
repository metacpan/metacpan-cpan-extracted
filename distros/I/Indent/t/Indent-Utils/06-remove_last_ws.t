use strict;
use warnings;

use Indent::Utils qw(remove_last_ws);;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $string = 'string   ';
remove_last_ws(\$string);
is($string, 'string');

# Test.
$string = "string \t \t";
remove_last_ws(\$string);
is($string, 'string');

# Test.
$string = "  string \t \t";
remove_last_ws(\$string);
is($string, '  string');
