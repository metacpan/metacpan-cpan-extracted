#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use POSIX qw(WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Linux::Event;

my $loop = Linux::Event->new(model => 'reactor');
my $pid = fork();
die "fork failed: $!" if !defined $pid;

if ($pid == 0) {
  sleep 1;
  exit 42;
}

$loop->pid($pid, sub ($loop, $pid, $status, $data) {
  if (!defined $status) {
    say "pid $pid exited; status unavailable";
  }
  elsif (WIFEXITED($status)) {
    say "pid $pid exited with code " . WEXITSTATUS($status);
  }
  elsif (WIFSIGNALED($status)) {
    say "pid $pid died from signal " . WTERMSIG($status);
  }

  $loop->stop;
});

$loop->run;
