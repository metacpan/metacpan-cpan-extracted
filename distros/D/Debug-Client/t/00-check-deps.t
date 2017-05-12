use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More;
use Test::CheckDeps;

check_dependencies();

if (1) {
	BAIL_OUT("Missing dependencies") if !Test::More->builder->is_passing;
}

done_testing;

__END__

