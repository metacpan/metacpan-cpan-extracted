use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

BEGIN {
	unless ( $ENV{RELEASE_TESTING} ) {
		require Test::More;
		Test::More::plan( skip_all => 'Author tests, not required for installation.' );
	}
}

use Test::More;
use Test::Requires { 'Test::Pod' => 1.48 };

all_pod_files_ok();

done_testing();

__END__
