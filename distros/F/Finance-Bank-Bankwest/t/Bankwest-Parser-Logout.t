use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::Parser' => {
        parser      => 'Logout',
        test_ok     => 'logged-out',
    },
);
done_testing;
