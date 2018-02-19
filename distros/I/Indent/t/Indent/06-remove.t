use strict;
use warnings;

use English qw(-no_match_vars);
use Indent;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Indent->new;
eval {
	$obj->remove('aa');
};
is($EVAL_ERROR, "Cannot remove indent 'aa'.\n", 'Remove bad indent.');

# Test.
$obj = Indent->new;
$obj->add('---');
my $ret = $obj->remove('---');
is($ret, 1, 'Return value of remove() with explicit indent.');
is($obj->get, '', 'Removing ok with explicit indent.');

# Test.
$obj = Indent->new;
$obj->add;
$ret = $obj->remove;
is($ret, 1, 'Return value of remove() with default indent.');
is($obj->get, '', 'Removing ok with default indent.');
