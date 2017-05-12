use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::Parser' => {
        parser      => 'Login',
        test_fail   => {
            'login-timeout'           => 'NotLoggedIn::Timeout',
            'login-bad-credentials'   => 'NotLoggedIn::BadCredentials',
            'login-no-credentials'    => 'NotLoggedIn::BadCredentials',
            'login-subsequent-login'  => 'NotLoggedIn::SubsequentLogin',
            'login'                   => 'NotLoggedIn::UnknownReason',
        },
    },
);
done_testing;
