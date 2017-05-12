use strict;
use Test::More tests => 7;

use_ok('Finance::Bank::Wachovia::Transaction');

my $t = Finance::Bank::Wachovia::Transaction->new(
	date					=> '10/10/2004',
	action				=> '',
	description			=> 'CHECK 798',
	withdrawal_amount	=> '100.00',
	deposit_amount		=> '',
	balance				=> '200.00',
	seq_no				=> '1',
	trans_code			=> '1234567890',
	check_num			=> '2'
);

isa_ok( $t, 'Finance::Bank::Wachovia::Transaction' );
is( $t->date(), '10/10/2004' );
is( $t->withdrawal_amount, '100.00' );
isa_ok( $t->date('10/11/2004'), 'Finance::Bank::Wachovia::Transaction');
is( $t->date(), '10/11/2004' );

my $t2 = Finance::Bank::Wachovia::Transaction->new();

$t2	->date('11/11/2004')
	->action('')
	->description('PAYDAY')
	->deposit_amount('20000000.00')
	->balance('20000000000.00')
	->seq_no('212')
	->trans_code('9876543211');
	
is( $t2->description(), 'PAYDAY' );
