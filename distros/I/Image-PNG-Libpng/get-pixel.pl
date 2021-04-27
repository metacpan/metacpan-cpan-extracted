#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use lib "$Bin/blib/lib";
use lib "$Bin/blib/arch";
use Image::PNG::Libpng ':all';
my $png = read_png_file ("$Bin/qrpng-small.png");
#my $png = read_png_file ("$Bin/unt/logo_icon128.v101.png");
#exit;
#my $png = read_png_file ("$Bin/examples/luv.png");
my $h = $png->height ();
my $w = $png->width ();
for my $y (0..$h-1) {
    # if ($y % 2 != 0) {
    # 	next;
    # }
    for my $x (0..$w-1) {
	# if ($x % 2 != 0) {
	#     next;
	# }
#	print "$y $x\n";
	my $pixel = $png->get_pixel ($x, $y);
#	print "$pixel\n";
	# if ($pixel->{red} > 100 &&
	#     $pixel->{green} < 100 &&
	#     $pixel->{blue} < 100) {
	if ($pixel->{gray}) {
	    print " ";
	}
	else {
	    print "#";
	}
    }
    print "\n";
}
