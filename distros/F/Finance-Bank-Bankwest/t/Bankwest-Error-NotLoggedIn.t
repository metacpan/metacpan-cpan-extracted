use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'NotLoggedIn',
        parent  => '',
    },
);
done_testing;
