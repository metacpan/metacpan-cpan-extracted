package
  Env::Modulecmd;

use strict;
use warnings;
use feature 'say';

sub _modulecmd {
  my ($cmd) = shift;
  say STDERR 'list' if $cmd eq 'list';
  say STDERR 'avail' if $cmd eq 'avail';
  say STDERR "$cmd @_" if $cmd =~ m/^(show|load|unload)$/;
  return 1;
}

sub import {
  die "do not import";
}

1;
