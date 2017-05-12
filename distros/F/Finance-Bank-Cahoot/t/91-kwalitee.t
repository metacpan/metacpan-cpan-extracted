#! /usr/bin/perl

use strict;
use warnings;

use Test::More;
if (not defined $ENV{AUTHOR_MODE}) {
  my $msg = 'Skipping Test::Kwalitee - author mode only';
  plan( skip_all => $msg );
}

eval { require Test::Kwalitee; Test::Kwalitee->import() };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
