#!/usr/bin/perl
#
# fixuplinks.pl
#
# version 1.00, 11-12-04, michael@bizsystems.com
#
#
use strict;

my $dir = shift @ARGV or die q|
Syntax: $0 path/to/files

|;

chop $dir if $dir =~ m|/$|;

opendir(D,$dir) or die "\nCould not open path to files: $dir\n\n";
my @file = grep(/html$/i,readdir(D));
foreach (@file) {
  my $file = $dir .'/'. $_;
  next unless open S, $file;
  unless (open T,'>'. $file . '.tmp') {
    close S;
    next;
  }
  while (<S>) {
    while ($_ =~ m|(<a href=")/([^>"]+">)|i) {
      my $pre = $` . $1; my $match = $2; my $post = $';
      $match =~ tr|/|-|;
      $_ = $pre . $match . $post;
    }
    print T $_;
  }
  close S;
  close T;
  rename $file . '.tmp', $file;
}
