use strict;
use warnings;

use File::Object;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new;
my $ret = $obj->get_file;
is($ret, undef, 'Undefined file.');

# Test.
$obj = File::Object->new(
	'dir' => [1, 2, 3],
	'file' => 'ex1.txt',
	'type' => 'file',
);
$ret = $obj->get_file;
is($ret, 'ex1.txt', 'Regular file.');
