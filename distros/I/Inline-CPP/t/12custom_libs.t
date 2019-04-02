use strict;
use warnings;

use Test::More;

use Inline::CPP::Config;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

use Inline CPP => 'DATA';

# We're verifying that libs are getting wrapped in an array ref as required.

use Inline CPP => config => libs => '-lstdc++',
  force_build => 1, clean_after_build => 0;

is( add( 1, 1, 1 ), 3, 'LIBS directive is OK.' );

done_testing();

__DATA__

__CPP__

int add ( int a, int b, int c ) {
    return a + b + c;
}
