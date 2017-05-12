#!/usr/bin/env perl
use Test::More tests => 1;
use File::Basename;
my $dir=dirname $0;

is( system("$dir/testSaxIndexMaker.pl $dir/a.indexMaker.xml $dir/144.pidres.xml"), 0);
