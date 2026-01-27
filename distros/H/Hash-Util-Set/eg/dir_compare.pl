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

my ($dir_lhs, $dir_rhs) = @ARGV;
my %files_lhs = scan_dir($dir_lhs);
my %files_rhs = scan_dir($dir_rhs);

my @different;
foreach my $path (keys_intersection %files_lhs, %files_rhs) {
  push @different, $path if $files_lhs{$path} != $files_rhs{$path};
}

my @only_lhs = keys_difference %files_lhs, %files_rhs;
my @only_rhs = keys_difference %files_rhs, %files_lhs;

say "\nOnly in $dir_lhs: ", scalar @only_lhs;
say "  $_" for sort @only_lhs;

say "\nOnly in $dir_rhs: ", scalar @only_rhs;
say "  $_" for sort @only_rhs;

say "\nDifferent sizes: ", scalar @different;
say "  $_" for sort @different;

say "\nSummary: ", 
      scalar @only_lhs, " + ",
      scalar @only_rhs, " + ",
      scalar @different, " differences";
