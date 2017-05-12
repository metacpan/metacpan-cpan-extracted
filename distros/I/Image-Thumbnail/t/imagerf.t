# imagerf - Test Imagersupply a filename write to file
use lib "../lib";
use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);
use Test::More;

use Cwd;

eval'require Imager';
if ( $@) {
	 plan skip_all => "Skip Imager tests - Imager not installed";
}
if (not grep {$_ eq 'jpg'} Imager->read_types){
	plan skip_all => "Skip Imager file test - No JPEG abaility in Imager";
}
else {
	plan tests => 5;
}
use_ok ("Image::Thumbnail"=>0.62);

my $cwd = cwd."/";
$cwd .= 't/' if $cwd !~ /[\\\/]t[\\\/]?$/;

my $t = new Image::Thumbnail(
#	CHAT=>1,
	module		=> "Imager",
	input		=> $cwd."test.jpg",
	size		=> 55,
	create		=> 1,
	outputpath	=> $cwd.'test_t.jpg',
);
isa_ok($t, "Image::Thumbnail");

ok( $t->{x}<=55,"x");
ok( $t->{y}<=55, "y");
unlink($cwd."test_t.jpg");

isa_ok( $t->{object}, "Imager");

