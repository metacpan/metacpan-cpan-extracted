# imagerobmp - Test Imager supply an object write to file
our $VERSION = sprintf("%d.%02d", q$Revision: 0.02 $ =~ /(\d+)\.(\d+)/);
use lib qw(lib ../lib);
use strict;
use Test::More;

BEGIN {
	use Cwd;
	eval'use Imager';
	if ( $@) {
		 plan skip_all => "Skip Imager tests - Imager not installed";
	} else {
		plan tests => 7;
	}
	use_ok ("Image::Thumbnail" => 0.65);
	use_ok( 'Imager');
}

my $cwd = cwd;
$cwd .= '/t/' if $cwd !~ /[\\\/]t[\\\/]?$/;

SKIP: {
	skip "No test file at ${cwd}/test.bmp", 4 unless -e $cwd.'/test.bmp';
	my $img = Imager->new;
	ok($img->read( file=>"$cwd/test.bmp"));
	isa_ok ($img, "Imager");
	my $t = new Image::Thumbnail(
	#	CHAT 		=> 1,
		input		=> $img,
		module		=> "Imager",
		size		=> 55,
		create		=> 1,
		outputpath	=>'test_t.bmp',
	);
	isa_ok ($img, "Imager");
	ok( $t->{x}<=55,"x");
	ok( $t->{y}<=55,"y");
	unlink("test_t.bmp");
};

