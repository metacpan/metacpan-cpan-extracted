#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

if ( $ENV{RELEASE_TESTING} ) {
  eval { require Test::Kwalitee; Test::Kwalitee->import }; ## no critic (eval)
  plan skip_all => 'Test::Kwalitee not installed: skip' if $@;
  unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt'; # Clean up.
}
else {
  my $msg = 'Author Test: Set $ENV{RELEASE_TESTING} true to run.';
  plan skip_all => $msg;
}
