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
	my $got = Image::ColorDetector::_main_color_name({
		RED		=> 0,
		ORANGE	=> 3,
		YELLOW	=> 0,
		LIME	=> 0,
		GREEN	=> 0,
		AQUA	=> 0,
		BLUE	=> 0,
		VIOLET	=> 0,
		PURPLE	=> 0,
	});

	is($got, 'ORANGE');
};


subtest 'an argument which has no color counts' => sub {
	my $got = Image::ColorDetector::_main_color_name({
		RED		=> 0,
		ORANGE	=> 0,
		YELLOW	=> 0,
		LIME	=> 0,
		GREEN	=> 0,
		AQUA	=> 0,
		BLUE	=> 0,
		VIOLET	=> 0,
		PURPLE	=> 0,
	});

	is($got, 'BLACK-AND-WHITE');
};

subtest 'a blank argument' => sub {
	my $got = Image::ColorDetector::_main_color_name();

	is($got, undef);
};




done_testing;

