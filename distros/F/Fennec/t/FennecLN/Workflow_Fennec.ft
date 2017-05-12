package TEST::Test::Workflow;
use strict;
use warnings;

use lib 't/lib';
use Fennec parallel => 0, test_sort => 'sort', with_tests => ['WorkflowTest'];

can_ok( __PACKAGE__, qw/describe it before_each after_each before_all after_all/ );

is( @{TEST_WORKFLOW->root_layer->child}, 2, "Loaded tests from WorkflowTest" );

done_testing;
