package TEST::Test::Workflow;
use strict;
use warnings;

use Test::More;
use Test::Workflow;
test_sort 'sort';

can_ok( __PACKAGE__, qw/describe it before_each after_each before_all after_all/ );

use lib 't/lib';
with_tests 'WorkflowTest';

is( @{TEST_WORKFLOW->root_layer->child}, 2, "Loaded tests from WorkflowTest" );

run_tests;
done_testing;

1;
