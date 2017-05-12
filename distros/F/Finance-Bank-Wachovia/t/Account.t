use strict;
use Test::More tests => 12;
my $summary_file = 'data/bank_summary.html';
my $detail_file  = 'data/bank_transactions.html';
my $summary_data;
my $detail_data;
my $account_num = '1234567891234';

{
	local $/ = undef;
	open( F, $summary_file ) or die "Couldn't open $summary_file";
	$summary_data = <F>;
	close F;
	open( F, $detail_file ) or die "Couldn't open $detail_file";
	$detail_data = <F>;
	close F;
}

use_ok('Finance::Bank::Wachovia::Account');
use_ok('Finance::Bank::Wachovia::Transaction');
use Finance::Bank::Wachovia::DataObtainer::WWW;
my $do = Finance::Bank::Wachovia::DataObtainer::WWW->new();
$do->cached_content->{'summary'} = $summary_data;
$do->cached_content->{'details'}{'1234567891234'} = $detail_data;
my $account = Finance::Bank::Wachovia::Account->new(
	number		=> $account_num,
	data_obtainer		=> $do, # this is necessary when not testing
);

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

isa_ok( $account, 'Finance::Bank::Wachovia::Account' );
is( $account->name(), 'exp access', 'tests attribute get' );
is( $account->type(), 'checking', 'tests attribute get' );
isa_ok( $account->type('saving'), 'Finance::Bank::Wachovia::Account', 'tests attribute set' );
is( $account->type(), 'saving', 'confirms attribute set' );
is( scalar(@{$account->get_transactions()}), 73, 'transactions');
ok( $account->get_transactions->[0]->date =~ m|^\d\d/\d\d/\d{4}$|, 'transactions are objects' );
$account->set_transactions();
is( scalar(@{$account->get_transactions()}), 0, 'remove transactions');
$account->set_transactions([$t,$t,$t]);
is( scalar(@{$account->get_transactions()}), 3, 'set transactions');
$account->add_transaction( $t );
is( scalar(@{$account->get_transactions()}), 4, 'add transaction');
