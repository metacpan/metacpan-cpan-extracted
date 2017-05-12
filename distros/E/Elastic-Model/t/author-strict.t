#!/usr/bin/env perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use Test::Strict;
all_perl_files_ok('lib/');
