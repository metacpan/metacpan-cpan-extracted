# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use File::Object;
use Image::Select;
use Imager::Color;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->dir('ex1')->set;

# Test.
eval {
	Image::Select->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Image::Select->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
eval {
	Image::Select->new;
};
is($EVAL_ERROR, "Parameter 'path_to_images' is required.\n",
	"Parameter 'path_to_images' is required.");
clean();

# Test.
my $obj = Image::Select->new(
	'path_to_images' => $data_dir->s,
);
isa_ok($obj, 'Image::Select');

# Test.
$obj = Image::Select->new(
	'path_to_images' => $data_dir->s,
	'type' => undef,
);
isa_ok($obj, 'Image::Select');

# Test.
eval {
	Image::Select->new(
		'path_to_images' => $data_dir->s,
		'type' => 'foo',
	);
};
is($EVAL_ERROR, "Image type 'foo' doesn't supported.\n",
	"Image type 'foo' doesn't supported.");
clean();
