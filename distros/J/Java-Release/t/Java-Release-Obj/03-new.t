use strict;
use warnings;

use English;
use Java::Release::Obj;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
eval {
	Java::Release::Obj->new;
};
like($EVAL_ERROR, qr{^\w+\ required}, 'No required parameters.');

# Test.
my $obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
);
isa_ok($obj, 'Java::Release::Obj');
