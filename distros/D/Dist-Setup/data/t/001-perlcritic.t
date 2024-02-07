#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;

use English;
use File::Spec;
use FindBin;

our $VERSION = 0.01;

BEGIN {
  if (not $ENV{EXTENDED_TESTING}) {
    skip_all('Extended test. Set $ENV{EXTENDED_TESTING} to a true value to run.');
  }
}

BEGIN {
  eval 'use Test2::Tools::PerlCritic';  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
  if ($EVAL_ERROR) {
    my $msg = 'Test2::Tools::PerlCritic required to criticise code';
    skip_all($msg);
  }
}

my @dirs;

sub add_if_exists {
  return push @dirs, $_[0] if -d $_[0];
  return;
}

if (!add_if_exists("${FindBin::Bin}/../blib")) {
  add_if_exists("${FindBin::Bin}/../lib");
}
add_if_exists("${FindBin::Bin}/../script");

perl_critic_ok(\@dirs);

done_testing;
