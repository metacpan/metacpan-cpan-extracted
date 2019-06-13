
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
eval "use Test::MinimumVersion 0.101082";
plan skip_all => "Test::MinimumVersion 0.101082 required to test minimum Perl version" if $@;
all_minimum_version_ok('5.18');
