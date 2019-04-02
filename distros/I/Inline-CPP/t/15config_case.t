use strict;
use warnings;
use Test::More tests => 1;

# Case insensitive Inline::CPP-specific config options verified in tests for
# namespace keyword.  Here, we will test pass through of an insensitive Inline
# option.  See t/namespace/06inherit.t for testing of insensitive Inline::CPP
# handled options.

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0,
  prefix => 'test_';

use Inline CPP => <<'EOCPP';

  int test_add ( int a, int b ) { return a + b; }

EOCPP

is add(2,2), 4, 'Case insensitive Inline::C-handled config option: prefix.';
