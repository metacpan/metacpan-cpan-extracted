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
	my $got = Image::ColorDetector::_allot_color_name([
			{
			  'h' => '24',
			  'v' => '0.0392156862745098',
			  's' => 255
			},
			{
			  'h' => '30',
			  'v' => '0.141176470588235',
			  's' => 255
			},
			{
			  'h' => '29.4736842105263',
			  'v' => '0.223529411764706',
			  's' => 255
			},
		]);

	is_deeply($got, [
		{
		  'color' => 'ORANGE',
		  'h' => 24,
		  'v' => '0.0392156862745098',
		  's' => 255
		},
		{
		  'color' => 'ORANGE',
		  'h' => 30,
		  'v' => '0.141176470588235',
		  's' => 255
		},
		{
		  'color' => 'ORANGE',
		  'h' => '29.4736842105263',
		  'v' => '0.223529411764706',
		  's' => 255
		}
	]);
};

subtest 'an argument which is a blank arrey reference' => sub {
	my $got = Image::ColorDetector::_allot_color_name([]);
	is_deeply($got, []);
};

subtest 'an argument which is a blank' => sub {
	my $got = Image::ColorDetector::_allot_color_name();
	is($got, undef);
};



done_testing;

