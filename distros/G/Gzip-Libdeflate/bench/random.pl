#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use Gzip::Faster;
use Gzip::Libdeflate;
use File::Slurper 'read_binary';

my $gf = Gzip::Faster->new ();
$gf->level (9);
my $gl = Gzip::Libdeflate->new (level => 12);
for my $alp (2..10) {
    for (my $len = 10; $len < 200; $len+=10) {
	my $mul = int (1000000 / $len);
	my $input = join '', map {(int(rand($alp)))x$len} 1..$mul;
	my $gfout = $gf->zip ($input);
	my $gflen = length ($gfout);
	my $glout = $gl->compress ($input);
	my $gllen = length ($glout);
	my $improve = 1- ($gllen / $gflen);
	if ($improve < -0.25) {
	    printf "%4d / %2d: %7d %5d %5d %5.1f%%\n", $len, $alp,
		length ($input), $gflen, $gllen, 100*$improve;
	}
    }
}
