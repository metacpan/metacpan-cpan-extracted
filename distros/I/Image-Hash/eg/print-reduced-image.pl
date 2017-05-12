#!/usr/bin/perl
use strict;
use warnings;

use lib "lib";

use Image::Hash;
use File::Slurp;
use Getopt::Std;

my %opts;
getopts('l:', \%opts);

my $module;
if ($opts{'l'}) {
        $module = $opts{'l'};
}


my $file = shift @ARGV or die("Pleas spesyfi a file to read!");

my $image = read_file( $file, binmode => ':raw' ) ;

my $ihash = Image::Hash->new($image, $module);

binmode STDOUT;
print STDOUT $ihash->reducedimage();
