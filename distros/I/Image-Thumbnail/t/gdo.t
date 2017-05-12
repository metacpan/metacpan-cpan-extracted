# imf - Test GD supply an object write to file
our $VERSION = sprintf("%d.%02d", q$Revision: 0.02 $ =~ /(\d+)\.(\d+)/);
use lib "../lib";
use strict;
use Test::More;

use Cwd;

eval'use GD';
if ( $@) {
	 plan skip_all => "Skip GD tests - GD not installed";
} else {
	plan tests => 6;
}
use_ok ("Image::Thumbnail" => '0.62');
use_ok( 'GD');

my $cwd = cwd;
$cwd .= '/t/' if $cwd !~ /[\\\/]t[\\\/]?$/;

SKIP: {
	skip "No test file at ${cwd}/test.jpg", 4 unless open IN, $cwd.'/test.jpg';
	my $img = GD::Image->newFromJpeg(*IN);
	close IN;
	isa_ok ($img, "GD::Image");
	my $t = new Image::Thumbnail(
	#	CHAT =>1,
		input	=> $img,
		module	=> "GD",
		size	=> 55,
		create	=> 1,
		outputpath =>'test_t.jpg',
	);
	isa_ok ($img, "GD::Image");
	ok( $t->{x}<=55,"x");
	ok( $t->{y}<=55,"y");
	unlink("test_t.jpg");
};

