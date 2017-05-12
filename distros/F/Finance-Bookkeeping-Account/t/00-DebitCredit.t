package CreditAccount;
use Moose;
with ('Finance::Bookkeeping::Account' => { nb => 'credit'});

package DebitAccount;
use Moose;
with ('Finance::Bookkeeping::Account' => { nb => 'debit'});

package main;

use strict;
use warnings;
use lib './lib';

use Test::More tests => 4;                      # last test to print

my $cr = CreditAccount->new;
$cr->credit(50);
is($cr->balance, 50, 'CreditAccount credited');

$cr->debit(20);
is($cr->balance,  30, 'CreditAccount debited');


my $dr = DebitAccount->new;
$dr->debit(10);

is($dr->balance, 10, 'DebitAccount debited');

$dr->credit(50);
is($dr->balance, -40, 'DebitAccount credited');

done_testing();
