#!perl
use warnings;
use strict;

use Test::More tests => 12;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('SimpleTest');

no warnings 'once';

#
#   IMPORT HANDLER
#

ok( $SimpleTest::TEST_ON_IMPORT,
    'import handler was called');
is( $SimpleTest::TEST_ON_IMPORT_CLASS, 'SimpleFilter',
    'import handler received correct class');
is_deeply($SimpleTest::TEST_ON_IMPORT_ARGS, [qw(foo 23 bar 13)],
    'import handler received correct arguments');

#
#   EOF HANDLER
#

ok( $SimpleTest::TEST_ON_EOF, 
    'eof handler was called');
is( $SimpleTest::TEST_ON_IMPORT_CLASS, 'SimpleFilter',
    'eof handler received correct class');

#
#   ORDER OF HANDLERS
#

is_deeply($SimpleTest::TEST_ORDER, [qw(on_import on_eof)],
    'handlers were called in correct order');

#
#   HANDLER CALLED IN CORRECT PHASE
#

ok( $SimpleTest::TEST_COMPILETIME,
    'import handler called before compilation');
ok( $SimpleTest::TEST_RUNTIME,
    'eof handler called before execution');

#
#   EXPORTING WORKED CORRECTLY
#

ok( SimpleTest->can('test_export'),
    'function was exported from filter');
is( SimpleTest->test_export, 23,
    'correct function was exported');

#
#   MODIFICATION WORKS
#

ok( $SimpleTest::TEST_MODIFICATION,
    'source code modification through @_ works');


