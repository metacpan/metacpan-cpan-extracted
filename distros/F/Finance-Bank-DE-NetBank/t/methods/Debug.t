#!perl

use strict;
use warnings;
use Test::More tests => 2;
use Finance::Bank::DE::NetBank;

my $account = Finance::Bank::DE::NetBank->new();

$account->Debug(1);
ok( $account->Debug(), 'debug enabled');

$account->Debug(undef);
ok( !$account->Debug(), 'debug disabled');

