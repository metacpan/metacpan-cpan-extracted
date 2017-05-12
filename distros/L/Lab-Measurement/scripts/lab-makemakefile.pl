#!/usr/bin/perl

open MKF ">Makefile" or die;

my $m=<<ENDOFMAKEFILE;

overview.pdf: overview.dvi
	dvipdf overview

overview.dvi: overview.tex overview.aux
	latex overview

overview.tex: *.meta filelist.txt
	make_overview.pl

ENDOFMAKEFILE

print MKF $m;
