use strict;
use warnings;

use Memory::Process;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Memory::Process->new;
my $ret = $obj->record;
is($ret, 1, 'Get number of records after record().');

# Test.
$obj->reset;
$ret = $obj->record('Foo');
is($ret, 1, 'Get number of records after reset() and record().');
