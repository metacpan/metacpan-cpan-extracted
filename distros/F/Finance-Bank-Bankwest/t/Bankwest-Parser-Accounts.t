use Test::Routine::Util;
use Test::More;

run_tests(
    undef,
    't::lib::Test::Parser' => {
        parser      => 'Accounts',
        parse_ok    => 'acct-balances',
        parse_type  => 'Account',
        parse       => [ {
            name                  => 'My Zero Transaction',
            number                => '303-111 0012345',
            balance               => '4485.20',
            credit_limit          => '100.00',
            uncleared_funds       => '0.00',
            available_balance     => '4479.70',
        } ],
    },
);
done_testing;
