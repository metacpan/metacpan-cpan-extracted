
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;

use Test::Code::TidyAll;
use Test::More;

tidyall_ok();
