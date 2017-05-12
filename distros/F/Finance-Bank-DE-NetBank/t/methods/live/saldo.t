#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Finance::Bank::DE::NetBank;

my %config = (
        CUSTOMER_ID => "demo",        # Demo Login
        PASSWORD    => "",            # Demo does not require a password
        ACCOUNT     => "1234567",     # Demo Account Number (Kontonummer)
);

my $account = Finance::Bank::DE::NetBank->new(%config);

ok($account->login(), 'login');
ok($account->saldo() eq "552,73", 'saldo should return the default saldo of the demo account');
