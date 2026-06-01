#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use IO::Select;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

opendir(my $dh, $Bin) or die "opendir failed: $!";
my @files = sort grep { /\.pl\z/ && $_ ne 'all.pl' } readdir($dh);
closedir $dh;

my @failed;

for my $file (@files) {
  my $path = "$Bin/$file";
  say '=' x 72;
  say "EXAMPLE: $file";
  say '=' x 72;

  my $err = gensym;
  my $pid = open3(my $in, my $out, $err, $^X, '-I', "$Bin/../lib", $path);
  close $in;

  my $sel = IO::Select->new($out, $err);
  while (my @ready = $sel->can_read) {
    for my $fh (@ready) {
      my $bytes = sysread($fh, my $buf, 8192);
      if (!defined $bytes) {
        next if $!{EINTR};
        $sel->remove($fh);
        close $fh;
        next;
      }
      if ($bytes == 0) {
        $sel->remove($fh);
        close $fh;
        next;
      }
      print $buf;
    }
  }

  waitpid($pid, 0);
  my $code = $? >> 8;
  say "exit=$code";
  push @failed, [ $file, $code ] if $code != 0;
}

say '';

if (@failed) {
  say "Examples failed:";
  for my $item (@failed) {
    my ($file, $code) = @$item;
    say "  $file exited with $code";
  }
  exit 1;
}

say "All examples complete.";
exit 0;
