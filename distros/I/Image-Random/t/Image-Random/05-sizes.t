use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Image::Random;
use Imager;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Image::Random->new;
my @ret = $obj->sizes;
is_deeply(
	\@ret,
	[
		1920,
		1080,
	],
	'Get default sizes of image.',
);

# Test.
@ret = $obj->sizes(110);
is_deeply(
	\@ret,
	[
		1920,
		1080,
	],
	'Get default sizes after bad set of sizes.',
);

# Test.
my $tempdir = tempdir('CLEANUP' => 1);
my $out_file = catfile($tempdir, 'foo.png');
$obj->create($out_file);
my $i = Imager->new;
$i->read('file' => $out_file);
is($i->getwidth, 1920, 'Get default width.');
is($i->getheight, 1080, 'Get default height.');
@ret = $obj->sizes(110, 90);
is_deeply(
	\@ret,
	[
		110,
		90,
	],
	'Get sizes after set of sizes.',
);
$obj->create($out_file);
$i->read('file' => $out_file);
is($i->getwidth, 110, 'Get width after change.');
is($i->getheight, 90, 'Get height after change.');
