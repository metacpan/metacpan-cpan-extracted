use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

# Test that all modules load properly

BEGIN {
  use_ok('IO::Pager');
  use_ok('IO::Pager::Unbuffered');
  use_ok('IO::Pager::Buffered');
  use_ok('IO::Pager::Page');
};

done_testing;
