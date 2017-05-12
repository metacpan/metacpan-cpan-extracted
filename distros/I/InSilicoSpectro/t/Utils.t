#!/usr/bin/env perl
use Test::More tests => 2;
use File::Basename;
my $dir=dirname($0)."/Utils";
my $env="INSILICOSPECTRO_DEFFILE=".dirname($0)."/InSilico/insilicodef-test.xml";
is( system("$env perl $dir/testIO.pl 0 $dir/?.txt >/dev/null"), 0);
is( system("$env perl $dir/testIO.pl 1 $dir/a.fasta.gz >/dev/null"), 0);
