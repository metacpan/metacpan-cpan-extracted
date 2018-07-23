use strict;
use warnings;
use utf8;

use Test::More;
if ( !eval { require Test::Pod::Coverage; 1 } ) {
	plan skip_all => q{Test::Pod::Coverage required for testing POD coverage};
}
Test::Pod::Coverage::all_pod_coverage_ok();
