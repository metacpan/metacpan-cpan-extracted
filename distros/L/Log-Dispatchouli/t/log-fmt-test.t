use strict;
use warnings;

use Test::More 0.88;

use Log::Fmt::Test;
use Log::Fmt;

Log::Fmt::Test->test_logfmt_implementation('Log::Fmt');

done_testing;
