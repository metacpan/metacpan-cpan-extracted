use strict;
use warnings;

use File::Object;
use File::Spec::Functions qw(catdir catfile splitdir);
use FindBin qw($Bin);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new;
my $right_ret = catdir(splitdir($Bin));
is($obj->s, $right_ret, 'Actual directory.');

# Test.
$obj = File::Object->new(
	'dir' => [1, 2, 3],
	'file' => 'ex1.txt',
	'type' => 'file',
);
$right_ret = catfile('1', '2', '3', 'ex1.txt');
is($obj->s, $right_ret, 'Path to specified file.');
