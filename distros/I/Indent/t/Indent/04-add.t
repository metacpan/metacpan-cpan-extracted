use strict;
use warnings;

use Indent;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Indent->new;
is($obj->get, '', 'No indent.');
$obj->add('---');
is($obj->get, '---', 'Add first indent.');
$obj->add('hoho');
is($obj->get, '---hoho', 'Add second indent.');
$obj->add;
is($obj->get, "---hoho\t", 'Add third (default) indent.');
