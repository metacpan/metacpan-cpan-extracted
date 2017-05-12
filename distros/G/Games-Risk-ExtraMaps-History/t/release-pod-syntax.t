#!perl
#
# This file is part of Games-Risk-ExtraMaps-History
#
# This software is Copyright (c) 2011 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Test::More;

eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok();
