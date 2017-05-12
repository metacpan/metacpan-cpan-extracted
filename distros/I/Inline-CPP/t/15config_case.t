use strict;
use warnings;
use Test::More tests => 1;

# Case insensitive Inline::CPP-specific config options verified in tests for
# namespace keyword.  Here, we will test pass through of an insensitive Inline
# option.  See t/namespace/06inherit.t for testing of insensitive Inline::CPP
# handled options.

use Inline CPP => config => prefix => 'test_';

use Inline CPP => <<'EOCPP';

  int test_add ( int a, int b ) { return a + b; }

EOCPP

is add(2,2), 4, 'Case insensitive Inline::C-handled config option: prefix.';
