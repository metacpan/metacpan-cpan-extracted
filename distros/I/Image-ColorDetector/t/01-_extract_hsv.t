use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;
use FindBin;

my $base_dir;
BEGIN { $base_dir = "$FindBin::Bin/.." }
use lib "$base_dir/lib";

use Image::ColorDetector;

subtest 'a valid argument' => sub {
	my $got = Image::ColorDetector::_extract_hsv("$base_dir/data/sample.png");

	is_deeply($got->[0],
		{
			'h' => '24',
			'v' => '0.0392156862745098',
			's' => 255
		}
	);
};

subtest 'an invalid image src' => sub {

	dies_ok { my $got = Image::ColorDetector::_extract_hsv("$base_dir/data/invalid.png") } 'should die because an argument is not a valid image format';

};

subtest 'an blank image src' => sub {

	my $got = Image::ColorDetector::_extract_hsv();
	is($got, undef);
};


done_testing;

