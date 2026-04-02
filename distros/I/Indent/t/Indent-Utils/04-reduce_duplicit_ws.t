use strict;
use warnings;

use Indent::Utils qw(reduce_duplicit_ws);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $string = 's   tring';
reduce_duplicit_ws(\$string);
is($string, 's tring', 'Change three spaces to one.');

# Test.
$string = "s \t\n  tring";
reduce_duplicit_ws(\$string);
is($string, 's tring', 'Change space, tab, newline, two spaces to one space.');

# Test.
$string = "s \t\n  t \t\n\ ring";
reduce_duplicit_ws(\$string);
is($string, 's t ring', 'Change multiple white characters to one space.');
