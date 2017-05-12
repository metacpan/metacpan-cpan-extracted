#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests skipped.  Set $ENV{RELEASE_TESTING} to run'
  unless $ENV{RELEASE_TESTING};


plan skip_all => 'Test::CPAN::Changes required for this test'
  unless eval 'use Test::CPAN::Changes; 1;';  ## no critic(eval)


changes_ok();

done_testing();
