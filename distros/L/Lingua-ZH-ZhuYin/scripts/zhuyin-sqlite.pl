#!/usr/bin/perl -w
use strict;

die "USAGE: zhuyin-sqlconvert file1 file2 ..." if (!@ARGV);

for my $fn (@ARGV) {
    open HNDL, "<$fn";
    my @a=($fn=~/(\w+)\.txt/);
    my $tblname=lc $a[0];
    
    print "create table $tblname (word, zhuyin);\n";
    printf "create index %s_index_word on %s (word);\n", $tblname, $tblname;
    printf "create index %s_index_zhuyin on %s (zhuyin);\n", $tblname, $tblname;
    print "begin;\n";
    my ($word, $zhuyin);
    while(<HNDL>) {
        chomp;
	$word = $_ if m/^\S+$/;
	$zhuyin = $1 if m/^注音一式(.*)$/;
	if ($zhuyin) {
	    my @zhuyins = split /\t/,$zhuyin;
	    foreach (@zhuyins) {
		s/　/  /g;
		s/^\s+//;
		s/\s+$//;
		s/^（.+）//;
		$word =~ s/，//;
		printf "insert into %s values ('%s', '%s');\n", $tblname, $word, $_;
	    }
	}
	$zhuyin = '';
    }
    print "commit;\n";
}

