#!perl
#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2019 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use Test::More;

use Test::MinimumVersion;
all_minimum_version_from_metayml_ok();
