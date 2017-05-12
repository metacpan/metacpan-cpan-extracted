
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}

use strict;
use warnings;

use Test::More;

## no critic
eval 'use Test::Code::TidyAll 0.20';
plan skip_all =>
    "Test::Code::TidyAll 0.20 required to check if the code is clean."
    if $@;
tidyall_ok();

