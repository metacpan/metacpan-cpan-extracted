#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use IPC::Open3 qw(open3);
use Symbol qw(gensym);

opendir(my $dh, $Bin) or die "opendir failed: $!";
my @files = sort grep { /\.pl\z/ && $_ ne 'all.pl' } readdir($dh);
closedir $dh;

for my $file (@files) {
  my $path = "$Bin/$file";
  print "
", ('=' x 72), "
";
  print "EXAMPLE: $file
";
  print ('=' x 72), "
";

  my $err = gensym;
  my $pid = open3(my $in, my $out, $err, $^X, '-I', "$Bin/../lib", $path);
  close $in;

  while (my $line = <$out>) {
    print $line;
  }
  while (my $line = <$err>) {
    print $line;
  }

  waitpid($pid, 0);
  my $code = $? >> 8;
  print "exit=$code
";
}

print "
All examples complete.
";
