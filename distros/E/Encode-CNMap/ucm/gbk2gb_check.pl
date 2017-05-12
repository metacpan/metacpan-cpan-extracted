#!/usr/bin/perl
# Ensure GB2312-add.dat is working

$VERSION = "0.30";

chdir "ucm" if !(-e "gb2312-add.dat");

use Encode::CNMap;

open RDAT, "gb2312-add.dat";
while(<RDAT>) {
	chomp;
	next unless /<U....> \\x..\\x.. \|1 # ([^-]*)->(.*)/;
	$gbk=$1;
	$gb2312=$2;
	$converted=$gbk;
	$converted=simp_to_gb($converted);
	if($converted eq $gb2312) {
		printf "$gbk -> $converted [OK]\n";
	} else {
		printf "==WRONG== $gbk -> $converted\n";
	}
}
close RDAT;