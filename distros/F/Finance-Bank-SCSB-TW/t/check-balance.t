#!/usr/bin/perl -w

use strict;
use Test::More;

unless ($ENV{TEST_SCSB_CREDENTIAL}) {
    plan skip_all => "define TEST_SCSB_CREDENTIAL env variable to run this test.";
    exit;
}

plan tests => 1;

my ($id, $username, $password) = split " ", $ENV{TEST_SCSB_CREDENTIAL};

use Finance::Bank::SCSB::TW;

my $balance = Finance::Bank::SCSB::TW::check_balance($id, $username, $password);

ok( $balance >= 0 );


diag "Your NTD balance: $balance\n";

