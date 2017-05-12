use strict;
use Test::More tests => 15;

use_ok('Finance::Bank::Wachovia::DataObtainer::WWW::Parser');

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

is((
Finance::Bank::Wachovia::DataObtainer::WWW::Parser
	->get_account_numbers( $summary_data ))[0], 
	$account_num, 'get_account_numbers worked' );

is(
Finance::Bank::Wachovia::DataObtainer::WWW::Parser
	->get_account_available_balance( $summary_data, $account_num ),
	'2087.72', 'get_account_available_balance worked' );
	
is(
Finance::Bank::Wachovia::DataObtainer::WWW::Parser
	->get_account_posted_balance( $detail_data ),
	'2242.66', 'get_account_posted_balance worked' );
	
is(
Finance::Bank::Wachovia::DataObtainer::WWW::Parser
	->get_account_name( $summary_data, $account_num ),
	'exp access', 'get_account_name worked' );
	
is(
Finance::Bank::Wachovia::DataObtainer::WWW::Parser
	->get_account_type( $detail_data ),
	'checking', 'get_account_type worked' );

my $trans = 
Finance::Bank::Wachovia::DataObtainer::WWW::Parser
	->get_account_transactions( $detail_data );
	
is( $trans->[0]{'date'}, '11/17/2004', 'get_account_transactions 1' );
is( $trans->[0]{'description'}, 'CHECK 896', 'get_account_transactions 2' );
is( $trans->[0]{'withdrawal_amount'}, '40.00', 'get_account_transactions 3' );
is( $trans->[0]{'balance'}, '-114.14', 'get_account_transactions 4' );
is( $trans->[-1]{'date'}, '12/02/2004', 'get_account_transactions 5' );
is( $trans->[-1]{'description'}, 'PURCHASE     WAWA #697                12/02', 'get_account_transactions 6' );
is( $trans->[-1]{'withdrawal_amount'}, '6.64', 'get_account_transactions 7' );
is( $trans->[-1]{'balance'}, '', 'get_account_transactions 8' );
is( $trans->[7]{'deposit_amount'}, '2368.69', 'get_account_transactions 9' );
