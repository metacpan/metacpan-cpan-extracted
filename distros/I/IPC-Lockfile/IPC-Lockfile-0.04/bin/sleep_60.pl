#!/usr/bin/env perl
use lib 'lib';
use IPC::Lockfile;

sleep(60);

=head1 NAME

sleep_60.pl - a tiny script for testing C<IPC::Lockfile>

=cut

=head1 SYNOPSIS

At the command line:

  $ sleep_60.pl&
  [1] 21802
  $ sleep_60.pl
  sleep_60.pl is running!
  Compilation failed in require at ./sleeper.pl line 3.
  BEGIN failed--compilation aborted at ./sleeper.pl line 3.
  $

=cut
