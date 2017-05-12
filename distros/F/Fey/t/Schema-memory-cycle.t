use strict;
use warnings;

use lib 't/lib';

use Test::Requires {
    'Test::Memory::Cycle' => 0,
};

use Fey::Test 0.05;
use Test::More 0.88;
use Test::Memory::Cycle;

memory_cycle_ok(
    Fey::Test->mock_test_schema(),
    'Make sure schema object does not have circular refs'
);

done_testing();
