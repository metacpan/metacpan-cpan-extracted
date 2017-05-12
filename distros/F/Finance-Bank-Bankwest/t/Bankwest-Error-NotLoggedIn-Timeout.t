use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'NotLoggedIn::Timeout',
        parent  => 'NotLoggedIn',
        text    => 'timed out due to inactivity',
    },
);
done_testing;
