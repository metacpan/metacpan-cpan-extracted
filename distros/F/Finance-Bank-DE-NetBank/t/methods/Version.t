#!perl

use strict;
use warnings;
use Test::More tests => 1;
use Finance::Bank::DE::NetBank;

my $account = Finance::Bank::DE::NetBank->new();
like( $account->Version(), qr/^\d\.\d{2}(_\d{2})?$/, 'Version() has to return a valid value');
