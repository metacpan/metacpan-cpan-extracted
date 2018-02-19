use strict;
use warnings;

use Indent::Utils qw(remove_first_ws);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $string = '   string';
remove_first_ws(\$string);
is($string, 'string');

# Test.
$string = "\t \t string";
remove_first_ws(\$string);
is($string, 'string');

# Test.
$string = "\t \t string  ";
remove_first_ws(\$string);
is($string, 'string  ');
