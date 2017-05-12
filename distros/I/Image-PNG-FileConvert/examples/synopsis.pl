#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use File::Compare;
use Image::PNG::FileConvert qw/file2png png2file/;
# Convert a data file into a PNG image
file2png ('myfile.txt', 'myfile.png');
# Extract a data file from a PNG image
png2file ('myfile.png', name => 'newfile.txt');
if (compare ('myfile.txt', 'newfile.txt') == 0) {
    print "Round trip OK\n";
}
