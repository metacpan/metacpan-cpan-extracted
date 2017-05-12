use strict;
use Test::More tests => 7;

use_ok('Finance::Bank::Wachovia::DataObtainer::WWW::Parser');

my $summary_file = 'data/bank_summary2.html';
my $credit_file  = 'data/credit_summary.html';
my $summary_data;
my $credit_data;
my @account_nums = ( '1111111111111', '2222222222222', '1234123412341234' ); 

{
local $/ = undef;
open( F, $summary_file ) or die "Couldn't open $summary_file";
$summary_data = <F>;
close F;
open( F, $credit_file ) or die "Couldn't open $credit_file";
$credit_data = <F>;
close F;
}

is(
	(Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_numbers( $summary_data ))[0].
	(Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_numbers( $summary_data ))[1].
	(Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_numbers( $summary_data ))[2],
	join('', @account_nums), 'get_account_numbers worked' );

is(
	Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_available_balance( $summary_data, $account_nums[0] ).
	Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_available_balance( $summary_data, $account_nums[1] ).
	Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_available_balance( $summary_data, $account_nums[2] ),
	'611.221100.981718.70', 'get_account_available_balance worked' );
	
is(
	Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_name( $summary_data, $account_nums[0] ).
	Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_name( $summary_data, $account_nums[1] ).
	Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_account_name( $summary_data, $account_nums[2] ),
	'free ckgpersonal savvisa platinum', 'get_account_name worked' );

# test credit data parsing
is( Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_credit_account_current_balance( $summary_data, $account_nums[2] ), '1718.70', 'get_credit_account_current_balance' );
is( Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_credit_account_limit( $credit_data ), '5500.00', 'get_credit_account_limit' );
is( Finance::Bank::Wachovia::DataObtainer::WWW::Parser->get_credit_account_available_credit( $credit_data ), '3781.00', 'get_credit_account_available_credit' );
	
