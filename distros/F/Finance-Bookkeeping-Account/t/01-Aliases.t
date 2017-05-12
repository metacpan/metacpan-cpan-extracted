package AssetAccount;
use Moose;
with ('Finance::Bookkeeping::Account' => { 
	nb => 'debit',
	-alias => {
		debit => 'deposit',
		credit => 'withdraw'
		},
	-excludes => ['debit', 'credit'],
	}
);

package main;

use strict;
use warnings;
use lib './lib';

use Test::More tests => 1;                      # last test to print

my $dr = AssetAccount->new;
$dr->deposit(10);
$dr->withdraw(5);

is($dr->balance, 5, 'Aliases deposit/withdraw');



done_testing();
