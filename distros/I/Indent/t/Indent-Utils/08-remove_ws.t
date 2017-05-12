# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Utils qw(remove_ws);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $string = 'string   ';
remove_ws(\$string);
is($string, 'string');

# Test.
$string = "string \t \t";
remove_ws(\$string);
is($string, 'string');

# Test.
$string = '   string';
remove_ws(\$string);
is($string, 'string');

# Test.
$string = "\t \t string";
remove_ws(\$string);
is($string, 'string');

# Test.
$string = "  string \t \t";
remove_ws(\$string);
is($string, 'string');

# Test.
$string = " \t \t string \t \t";
remove_ws(\$string);
is($string, 'string');
