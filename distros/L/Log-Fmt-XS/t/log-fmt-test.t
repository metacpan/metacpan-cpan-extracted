use strict;
use warnings;

use Test::More 0.88;

use Log::Fmt::Test;
use Log::Fmt::XS;

Log::Fmt::Test->test_logfmt_implementation('Log::Fmt::XS');

done_testing;
