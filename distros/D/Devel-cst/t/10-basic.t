#! perl

use strict;
use warnings FATAL => 'all';

use Test::More 0.89;

use Devel::CStacktrace qw/stacktrace/;

ok eval { stacktrace(12) }, 'Can lookup stacktrace';

done_testing;
