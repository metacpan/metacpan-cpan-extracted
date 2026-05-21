#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Compress::Gzip qw(gzip);
use IO::Uncompress::Gunzip qw(gunzip);
use File::Raw qw(import);
use File::Raw::Gzip;

eval { require File::Raw::Separated; File::Raw::Separated->import; 1 }
    or plan skip_all => "File::Raw::Separated not installed";

my $dir = tempdir(CLEANUP => 1);

# READ chain: .csv.gz -> AoA via plugin => ['gzip', 'csv'].
my $csv = "a,b,c\n1,2,3\n4,5,6\n";
my $path = "$dir/numbers.csv.gz";
gzip(\$csv, $path) or die "gzip failed";

my $rows = file_slurp($path, plugin => ['gzip', 'csv']);
is_deeply($rows,
          [['a','b','c'], ['1','2','3'], ['4','5','6']],
          'chain plugin=[gzip,csv]: read .csv.gz into AoA');

# WRITE chain: AoA -> .csv.gz via plugin => ['gzip', 'csv'].
my $out = "$dir/out.csv.gz";
file_spew($out, [['x','y'],['10','20'],['30','40']],
          plugin => ['gzip', 'csv']);

my $unc;
gunzip($out => \$unc) or die "gunzip failed";
is($unc, "x,y\n10,20\n30,40\n", 'chain write produced expected csv bytes');

# Round-trip via slurp on the file we just wrote.
my $back = file_slurp($out, plugin => ['gzip', 'csv']);
is_deeply($back,
          [['x','y'],['10','20'],['30','40']],
          'chain round-trip: spew then slurp returns the same AoA');

done_testing;
