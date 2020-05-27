use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Image::Checkerboard;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Image::Checkerboard->new;
my $ret = $obj->type;
is($ret, 'bmp', 'Get default image type (bmp).');

# Test.
eval {
	$obj->type('bad_type');
};
is($EVAL_ERROR, "Image type 'bad_type' doesn't supported.\n",
	'Unsupported image type.');
clean();

# Test.
$ret = $obj->type('png');
is($ret, 'png', 'Set image type (png).');
