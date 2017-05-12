#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use File::Slurper 'read_binary';
use FindBin '$Bin';
use Gzip::Faster 'inflate';
my $pngfile = "$Bin/larry-wall.png";
my $pngdata = read_binary ($pngfile);
if ($pngdata !~ /IHDR(.{13})/) {
    die "No header";
}
my ($height, $width, $bits) = unpack ("NNCCCCC", $1);
if ($pngdata !~ /(....)IDAT(.*)$/s) {
    die "No image data";
}
my $length = unpack ("N", $1);
my $data = substr ($2, 0, $length);
my $idat = inflate ($data);
for my $y (0..$height - 1) {
    my $row = substr ($idat, $y * ($width + 1), ($y + 1) * ($width + 1));
    for my $x (1..$width - 1) {
	my $pixel = substr ($row, $x, $x + 1);
	if (ord ($pixel) < 128) {
	    print "#";
	    next;
	}
	print " ";
    }
    print "\n";
}
