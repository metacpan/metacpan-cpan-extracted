use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Image::Random;
use Imager::Color;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
eval {
	Image::Random->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Image::Random->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Image::Random->new;
isa_ok($obj, 'Image::Random');

# Test.
$obj = Image::Random->new(
	'type' => undef,
);
isa_ok($obj, 'Image::Random');

# Test.
eval {
	Image::Random->new(
		'color' => 'red',
	);
};
is($EVAL_ERROR, "Bad background color definition. Use Imager::Color ".
	"object.\n", "Bad background color definition. Use Imager::Color ".
	"object.");
clean();

# Test.
$obj = Image::Random->new(
	'color' => Imager::Color->new('#C0C0FF'),
);
isa_ok($obj, 'Image::Random');

# Test.
eval {
	Image::Random->new(
		'type' => 'foo',
	);
};
is($EVAL_ERROR, "Image type 'foo' doesn't supported.\n",
	"Image type 'foo' doesn't supported.");
clean();
