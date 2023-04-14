use strict;
use warnings;

use Memory::Process;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Memory::Process->new;
my $ret_ar = $obj->state;
is(scalar @{$ret_ar}, 0, 'No recorded stays.');

# Test.
$obj->record('Foo');
$ret_ar = $obj->state;
is(scalar @{$ret_ar}, 1, 'One recorded stay.');
is(scalar @{$ret_ar->[0]}, 7, 'Stay item has 7 values.');
