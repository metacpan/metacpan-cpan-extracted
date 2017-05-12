use strict;
use warnings;
use Image::QRCode::Effects;
use Image::Magick;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);

my $tests = [
	{
		args => { wave => 1 },
		test_file => 'test_wave.jpg',
	},
	{
		args => { round_corners => 1 },
		test_file => 'test_corners.jpg',
	},
	{
		args => {
			gradient => 1,
			inner_shadow => 1,
		},
		test_file => 'test_gradient_and_shadow.jpg',
	},
];

my $img_dir = abs_path(dirname(__FILE__).'/test_images');

for my $test (@$tests) {
    my %args      = %{ $test->{args} };
		my $test_name = basename($test->{test_file});
		my $test_file = "$img_dir/$test->{test_file}";
    my $image     = Image::QRCode::Effects->new(
        level => 'H',
        plot  => "test $test_name",
    );
    my $tmpfile = File::Temp->new(SUFFIX => '.jpg');
    $image->write( %args, outfile => $tmpfile);
		close $tmpfile;
		my $img1 = Image::Magick->new();
		$img1->Read($tmpfile->filename);
		my $img2 = Image::Magick->new();
		$img2->Read($test_file);
		my $difference=$img1->Compare(image=>$img2, metric=>'rmse');
		ok($difference->Get('error') < 0.1, $test_name);
}

done_testing();
