use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::Parser' => {
        parser      => 'ServiceMessage',
        test_fail   => { 'service-message' => 'ServiceMessage' },
    },
);
done_testing;
