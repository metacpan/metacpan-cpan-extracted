#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Image::Similar 'load_image';
use Imager;
for my $n (100, 1000) {
    my $image = "$Bin/../t/images/lenagercke/lena-$n.png";
    my $imager = Imager->new ();
    $imager->read (file => $image);
    my $is = load_image ($imager);
    print $is->signature (), "\n";
}

