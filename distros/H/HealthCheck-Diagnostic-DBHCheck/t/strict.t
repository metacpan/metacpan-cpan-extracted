use strict;
use warnings;
use Test::Strict;

# Need a newer Dist::Zilla for this to not fail.
local $Test::Strict::TEST_SKIP = ['t/author-pod-coverage.t'];

all_perl_files_ok("lib", "t");
