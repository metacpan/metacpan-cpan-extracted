#!perl

use strict;
use warnings;
use Test::More tests => 4;
#open(STDERR, ">/tmp/STDERR.out");


use Finance::Bank::DE::NetBank;

my %config = (
        CUSTOMER_ID => "demo",        # Demo Login
        PASSWORD    => "",            # Demo does not require a password
        ACCOUNT     => "1234567",     # Demo Account Number (Kontonummer)
);

my $account = Finance::Bank::DE::NetBank->new(%config);

ok( defined($account->login()), 'login with offical demo login works');

$account->CUSTOMER_ID("broken");
ok( !defined($account->login()), 'broken credentials must not work' );
ok( !defined($account->statement()), 'statement() must not work with broken credentials' );
ok( !defined($account->saldo()), 'saldo() must not work with broken credentials' );

