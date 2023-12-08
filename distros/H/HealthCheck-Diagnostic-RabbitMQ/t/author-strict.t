
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use warnings;
use strict;
use Test::Strict;

all_perl_files_ok("lib", "t");
