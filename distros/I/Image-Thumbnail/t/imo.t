# imf - Test ImageMagick from object
use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 0.03 $ =~ /(\d+)\.(\d+)/);
use Test::More;

BEGIN {
	use Cwd;
	use lib "..";
	eval'require Image::Magick';
	if ( $@) {
		 plan skip_all => "Skip Image Magick tests - IM not installed";
	} else {
		plan tests => 4;
	}
}

use_ok("Image::Thumbnail");

my $cwd = cwd."/";
$cwd .= 't/' if $cwd !~ /[\\\/]t[\\\/]?$/;

my $img = new Image::Magick;

$img->Read($cwd.'test.jpg');

my $t = new Image::Thumbnail(
#	CHAT=>1,
	object=>$img,
	size=>55,
	create=>1,
	outputpath=>$cwd.'/test_t.jpg',
);

ok( defined $t->{x}, "Defined X");

ok ( $t->{x}==55, "x");
ok ( $t->{y}==48, "y");
unlink("test_t.jpg");

