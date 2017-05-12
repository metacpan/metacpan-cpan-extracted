use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'NotLoggedIn::SubsequentLogin',
        parent  => 'NotLoggedIn',
        text    => 'terminated due to a subsequent login',
    },
);
done_testing;
