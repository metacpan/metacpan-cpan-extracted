#!perl

use strict;
use warnings;
use Test::More tests => 1;
use Finance::Bank::DE::NetBank;

my $account = Finance::Bank::DE::NetBank->new();
ok($account->isa('Finance::Bank::DE::NetBank'), 'new() constructs an Finance::Bank::DE::NetBank instance');
