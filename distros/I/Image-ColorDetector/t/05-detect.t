use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use FindBin;

my $base_dir;
BEGIN { $base_dir = "$FindBin::Bin/.." }
use lib "$base_dir/lib";

use Image::ColorDetector qw( detect );

subtest 'a valid argument' => sub {
	my $got = detect("$base_dir/data/sample.png");
	is($got, 'ORANGE');
};

subtest 'an invalid image file which is not a binary file' => sub {
	dies_ok { my $got = detect("$base_dir/data/invalid.png") } 'should die because an argument is not a valid image format';
};


done_testing;

