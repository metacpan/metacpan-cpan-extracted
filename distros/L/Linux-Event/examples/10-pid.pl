#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use POSIX qw(WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG);
use Linux::Event;

my $loop = Linux::Event->new;

my $pid = fork();
die "fork: $!" if !defined $pid;

if ($pid == 0) {
  # child
  sleep 1;
  exit 42;
}

my $sub = $loop->pid($pid, sub ($loop, $pid, $status, $data) {
  if (!defined $status) {
    say "[loop] child $pid exited (status unavailable)";
  } elsif (WIFEXITED($status)) {
    say "[loop] child $pid exited code=" . WEXITSTATUS($status);
  } elsif (WIFSIGNALED($status)) {
    say "[loop] child $pid died by signal=" . WTERMSIG($status);
  } else {
    say "[loop] child $pid status=$status";
  }

  $loop->stop;
});

$loop->run;

# Reap is handled by pid() by default, but if you used reap => 0 you would
# need to waitpid() here to avoid a zombie.
