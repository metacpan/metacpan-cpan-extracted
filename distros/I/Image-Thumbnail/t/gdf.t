# gdf - Test GD supply a filename write to file
use lib "../lib";
use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);
use Test::More;

use Cwd;

eval'require GD';
if ( $@) {
	 plan skip_all => "Skip GD tests - GD not installed";
} else {
	plan tests => 6;
}

use_ok ("Image::Thumbnail" => 0.62);

my $cwd = cwd."/";
$cwd .= 't/' if $cwd !~ /[\\\/]t[\\\/]?$/;
ok(-e $cwd."test.jpg",'test file');

my $t = new Image::Thumbnail(
#	CHAT=>1,
	module	=> "GD",
	input	=> $cwd."test.jpg",
	size	=> 55,
	create	=> 1,
	outputpath => $cwd.'test_t.jpg',
);
isa_ok($t, "Image::Thumbnail");

ok( $t->{x}<=55,"x");
ok( $t->{y}<=55, "y");
unlink($cwd."test_t.jpg");

isa_ok( $t->{object}, "GD::Image");

