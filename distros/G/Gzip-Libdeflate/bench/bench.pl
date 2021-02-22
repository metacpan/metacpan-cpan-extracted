#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Gzip::Faster;
use Gzip::Libdeflate;
use File::Slurper 'read_binary';

for my $file (@ARGV) {
    if (! -f $file || -s $file == 0 || -s $file > 2e7) {
next;
}
my $input = read_binary ($file);#join '', map {(int(rand(2)))x50} 0..0x10000;
print "$file: ";
my $gf = Gzip::Faster->new ();
$gf->level (9);
my $gfout = $gf->zip ($input);
my $gflen = length ($gfout);
my $gl = Gzip::Libdeflate->new (level => 12);
my $glout = $gl->compress ($input);
my $gllen = length ($glout);
my $improve = 1- ($gllen / $gflen);
printf "%.1f%%", 100*$improve;
print "\n";
}
