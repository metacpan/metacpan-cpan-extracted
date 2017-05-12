# imfa - Test ImageMagick to/from file with attributes
use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 0.03 $ =~ /(\d+)\.(\d+)/);



BEGIN {
	use lib "..";
	use Test::More;
	use Cwd;

	eval'use Image::Magick';
	if ( $@) {
		 plan skip_all => "Skip IM tests - IM not installed";
	} else {
		plan tests => 6;
	}
	use_ok ("Image::Thumbnail");
}

my $cwd = cwd."/";
$cwd .= 't/' if $cwd !~ /[\\\/]t[\\\/]?$/;

my $t = new Image::Thumbnail(
#	CHAT=>1,
	size=>55,
	create=>1,
	inputpath=>$cwd.'/test.jpg',
	outputpath=>$cwd.'/test_t.jpg',
	attr=> {
		antialias => 'true',
	}
);

warn "# ".$t->{error} if $t->{error};

isa_ok($t, "Image::Thumbnail");
isa_ok($t->{object}, "Image::Magick");

ok ( defined $t->{x}, "x defined");
ok ( $t->{x}==55, "correct x");
ok ( $t->{y}==48, "correct y");
unlink($cwd."t/test_t.jpg");
