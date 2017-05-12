#!perl

use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('LevelTest');

no warnings 'once';

#
#   PHASE TESTS
#

ok( $LevelTest::TEST_COMPILETIME,
    'import handler ran on correct point');
ok( $LevelTest::TEST_RUNTIME,
    'eof handler ran on correct point');

#
#   EXPORT OVER TWO LEVELS TEST
#

ok( LevelTest->can('test_export'),
    'export over 2 levels successful');
is( LevelTest->test_export, 23,
    'correct function exported over 2 levels');


