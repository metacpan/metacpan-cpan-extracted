use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::ErrorSubclass' => {
        class   => 'NotLoggedIn::BadCredentials',
        parent  => 'NotLoggedIn',
        text    => 'invalid PAN/access code',
    },
);
done_testing;
