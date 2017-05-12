use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => {
        class       => 'Account',
        good_args   => {
            name                => 'My Zero Transaction',
            number              => '303-111 0012345',
            balance             => 4224.35,
            credit_limit        => 100.00,
            uncleared_funds     => 0.00,
            available_balance   => 4207.66,
        },
    },
);
done_testing;
