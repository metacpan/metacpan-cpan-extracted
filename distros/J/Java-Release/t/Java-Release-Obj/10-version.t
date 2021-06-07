use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Java::Release::Obj;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
);
my $ret = $obj->version;
is($ret, 1, 'Get version (only release).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
	update => 30,
);
$ret = $obj->version;
is($ret, '1.0.30', 'Get version (release and update).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	interim => 2,
	os => 'linux',
	release => 1,
	update => 30,
);
$ret = $obj->version;
is($ret, '1.2.30', 'Get version (release, interim and update).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	interim => 2,
	os => 'linux',
	patch => 1,
	release => 1,
	update => 30,
);
$ret = $obj->version;
is($ret, '1.2.30.1', 'Get version (release, interim, patch and update).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
);
$ret = $obj->version('old');
is($ret, '1', 'Get version (release, old format).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
	update => 234,
);
$ret = $obj->version('old');
is($ret, '1u234', 'Get version (release and update, old format).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
	update => 234,
);
$ret = $obj->version('new');
is($ret, '1.0.234', 'Get version (release and update, new format).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
	update => 234,
);
eval {
	$obj->version('foo');
};
is($EVAL_ERROR, "Bad version type. Possible values are 'new' or 'old'.\n",
	"Bad version type. Possible values are 'new' or 'old'.");
clean();

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	interim => 2,
	os => 'linux',
	release => 1,
	update => 30,
);
eval {
	$obj->version('old');
};
is($EVAL_ERROR, "Cannot create old version of version with interim or patch value.\n",
	"Cannot create old version of version with interim or patch value.");
clean();

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	patch => 2,
	release => 1,
	update => 30,
);
eval {
	$obj->version('old');
};
is($EVAL_ERROR, "Cannot create old version of version with interim or patch value.\n",
	"Cannot create old version of version with interim or patch value.");
clean();
