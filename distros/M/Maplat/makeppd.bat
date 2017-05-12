@echo off
echo This is a very dump script to generate a PPD/PPM file pair
echo for ActiveState Perl

perl Makefile.PL
nmake
tar cvf Maplat.tar blib
gzip --best Maplat.tar
nmake ppd
notepad Maplat.ppd

