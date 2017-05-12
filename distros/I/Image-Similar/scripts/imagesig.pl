#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use lib '/home/ben/projects/image-similar/blib/lib';
use lib '/home/ben/projects/image-similar/blib/arch';
use Image::Similar ':all';
use Imager;
for (@ARGV) {
    my $imager = Imager->new ();
    my $ok = $imager->read (file => $_);
    if (!$ok) {
	warn $imager->errstr ();
	next;
    }
    my $is = load_image ($imager);
    print $is->signature (), "\n";
}

