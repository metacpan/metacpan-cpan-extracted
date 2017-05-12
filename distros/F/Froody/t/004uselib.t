#!/usr/bin/perl
#
# Make sure no tests contain 'use lib', which confuses Devel::Cover a lot.
# If you want "prove t/test.t" to just work, use "prove -l".

use strict;
use warnings;
use Test::More;
use File::Find::Rule;

my @files = File::Find::Rule->file()->name('*.t')->in('t');

plan tests => scalar @files;

foreach my $test ( @files ) {
  my $fh;
  local $/;
  open $fh, $test;
  my $file = <$fh>;
  if ($file =~ m/\nuse\s+lib(.*?);/m) {
    my @list = grep {defined $_} eval $1;
    if (grep { !m/\bt\b/ } @list) {
      diag "found ".join(',',@list)." in $test";
      ok(0, $test);
      next;
    }
  }
  ok(1, $test);
}
