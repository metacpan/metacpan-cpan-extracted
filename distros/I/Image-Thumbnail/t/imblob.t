# imblob - Test ImageMagick blobs
our $VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);

use lib "../lib";
use strict;
use Test::More;

use Cwd;
BEGIN {
	eval'use Image::Magick';
	if ( $@) {
		 plan skip_all => "Skip IM tests - IM not installed";
	} else {
		plan tests => 7;
	}
	use_ok ("Image::Thumbnail" => 0.62);
}

my $cwd = cwd."/";
$cwd .= 't/' if $cwd !~ /[\\\/]t[\\\/]?$/;

ok( -e $cwd.'/test.jpg', "Test image present");

die "BAIL OUT! # WRONG VERSION" if $Image::Thumbnail::VERSION < 0.5;

my ($in, $blob);
open $in, $cwd.'/test.jpg';
binmode $in;
read $in, $blob, -s $in;
close $in;

my $t = new Image::Thumbnail(
#	CHAT=>1,
	size		=> 55,
	create		=> 1,
	input		=> \$blob,
	outputpath	=> $cwd.'/test_t.jpg',
);

warn "# ".$t->{error} if $t->{error};

isa_ok($t, "Image::Thumbnail");
isa_ok($t->{object}, "Image::Magick");

ok ( defined $t->{x}, "defined x");
ok ( $t->{x}==55, "correct x");
ok ( $t->{y}==48, "correct y");
unlink($cwd."t/test_t.jpg");

