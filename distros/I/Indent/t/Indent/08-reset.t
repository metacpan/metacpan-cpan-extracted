# Pragmas.
use strict;
use warnings;

# Modules.
use Indent;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Indent->new;
is($obj->get, '', 'No indent.');
$obj->add('---');
is($obj->get, '---', 'Add indent.');
$obj->reset;
is($obj->get, '', 'Indent after reset.');

# Test.
$obj = Indent->new;
is($obj->get, '', 'No indent.');
$obj->reset('|||');
is($obj->get, '|||', 'Reset to concrete indent.');
