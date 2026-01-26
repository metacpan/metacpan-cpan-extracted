#!/usr/bin/env perl
# Example: Compare two directories and report differences
use strict;
use warnings;
use v5.10;

use File::Find      qw[];
use File::Spec      qw[];
use Hash::Util::Set qw[ keys_difference 
                        keys_intersection ];

sub scan_dir {
  my ($dir) = @_;

  my %files;
  File::Find::find(sub {
    return unless -f;
    my $rel = File::Spec->abs2rel($File::Find::name, $dir);
    $files{$rel} = -s _;
  }, $dir);

  return %files;
}

die "Usage: $0 <dir1> <dir2>\n" unless @ARGV == 2;

my ($dir1, $dir2) = @ARGV;
my %files1 = scan_dir($dir1);
my %files2 = scan_dir($dir2);

my @different;
for my $f (keys_intersection %files1, %files2) {
  push @different, $f if $files1{$f} != $files2{$f};
}

my @only_left  = keys_difference %files1, %files2;
my @only_right = keys_difference %files2, %files1;

say "\nOnly in $dir1: ", scalar @only_left;
say "  $_" for sort @only_left;

say "\nOnly in $dir2: ", scalar @only_right;
say "  $_" for sort @only_right;

say "\nDifferent sizes: ", scalar @different;
say "  $_" for sort @different;

say "\nSummary: ", 
      scalar @only_left, " + ",
      scalar @only_right, " + ",
      scalar @different, " differences";
