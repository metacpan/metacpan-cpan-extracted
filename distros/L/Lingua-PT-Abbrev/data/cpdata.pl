#!/usr/bin/perl

use File::Copy;

my $dir = './blib/lib/Lingua/PT/Abbrev';

unless (-d $dir) {
  mkdir $dir or die "Well, I can't seem to create $dir - $!\n";
}

copy("data/abbrev.dat","$dir/abbrev.dat");



