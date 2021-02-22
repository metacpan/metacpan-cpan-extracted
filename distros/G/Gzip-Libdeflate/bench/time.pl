#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Gzip::Faster;
use Gzip::Libdeflate;
use File::Slurper 'read_binary';
use utf8;
use FindBin '$Bin';
use Time::HiRes;

for my $file (@ARGV) {
    if (! -f $file || -s $file == 0 || -s $file > 2e7) {
	next;
    }
    my $input = read_binary ($file); #join '', map {(int(rand(2)))x50} 0..0x10000;
    print "$file: ";
    my $gf = Gzip::Faster->new ();
    $gf->level (6);
    my $gfout = $gf->zip ($input);
    my $gflen = length ($gfout);
    my $gl = Gzip::Libdeflate->new (level => 6);
    my $glout = $gl->compress ($input);
    my $gllen = length ($glout);
    my $improve = 1- ($gllen / $gflen);
    printf "%.1f%%", 100*$improve;
    print "\n";
    bencht ($gl, $gf, 10000, $input);
}

sub bencht
{
    my ($gl, $gf, $count, $input) = @_;

    if (length ($input) > 1e6) {
	$count /= 100;
    }

    my $t1 = Time::HiRes::time; 
    for (1..$count) {
	$gl->compress ($input);
    }
    my $gltime = Time::HiRes::time - $t1;
    my $t2 = Time::HiRes::time; 
    for (1..$count) {
	$gf->zip ($input);
    }
    my $gftime = Time::HiRes::time - $t2;
    printf "GL time: %.2f; GF time: %.2f Ratio: %.2f\n",
	$gltime, $gftime, $gltime/$gftime;
}

