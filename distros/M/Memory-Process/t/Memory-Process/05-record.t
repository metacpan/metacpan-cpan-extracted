# Pragmas.
use strict;
use warnings;

# Modules.
use Memory::Process;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Memory::Process->new;
my $ret = $obj->record;
is($ret, 1, 'Get number of records.');

# Test.
$ret = $obj->record('Foo');
is($ret, 2, 'Get number of records.');
