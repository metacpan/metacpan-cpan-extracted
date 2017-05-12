use strict;
use warnings;

use Test::More;

use Devel::StackTrace;

isa_ok( 'Devel::StackTraceFrame', 'Devel::StackTrace::Frame' );

done_testing();
