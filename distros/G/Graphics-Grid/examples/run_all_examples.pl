#!/usr/bin/env perl

use 5.014;
use warnings;

use Data::Dumper;
use FindBin;
use File::Basename qw(basename);

my $my_basename  = basename $0;
my $examples_dir = $FindBin::RealBin;

my @example_scripts =
  grep { basename($_) ne $my_basename } glob("$examples_dir/*.pl");

say "example scripts: "
  . Dumper( [ map { basename $_ } @example_scripts ] );

for my $script (@example_scripts) {
    say "running $script";
    system("$^X -I$FindBin::RealBin/../lib $script");
}

say "done";
