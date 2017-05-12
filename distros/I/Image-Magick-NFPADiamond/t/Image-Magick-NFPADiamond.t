# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Image-Magick-NFPADiamond.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use File::Temp qw/ tmpnam /;;
use Test::More tests => 6;
BEGIN { use_ok('Image::Magick::NFPADiamond') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Image::Magick::NFPADiamond;

my $img1=Image::Magick::NFPADiamond->new();

ok( defined $img1, "Blank constructor");

isa_ok($img1->handle(), "Image::Magick", "Handle method");

my $img=Image::Magick::NFPADiamond->new(red=>1, blue=>2, yellow=>3);

ok( defined $img, "Sample diamond");

open ( my $saveout,'>&', *STDOUT) or die $!;

$tmp=tmpnam().'.jpg';

ok(! $img->save($tmp), "Save method");

@stats=stat($tmp);

ok( $stats[7]> 8000, "Generated file");

unlink $tmp;

