use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Image::Checkerboard;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
eval {
	Image::Checkerboard->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Image::Checkerboard->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Image::Checkerboard->new;
isa_ok($obj, 'Image::Checkerboard');

# Test.
$obj = Image::Checkerboard->new(
	'type' => undef,
);
isa_ok($obj, 'Image::Checkerboard');

# Test.
eval {
	Image::Checkerboard->new(
		'type' => 'foo',
	);
};
is($EVAL_ERROR, "Image type 'foo' doesn't supported.\n",
	"Image type 'foo' doesn't supported.");
clean();
