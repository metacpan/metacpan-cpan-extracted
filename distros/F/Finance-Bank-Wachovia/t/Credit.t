use strict;
use Test::More tests => 11;
my $summary_file = 'data/bank_summary2.html';
my $detail_file  = 'data/credit_summary.html';
my $summary_data;
my $detail_data;
my $account_num = '1234123412341234';

{
	local $/ = undef;
	open( F, $summary_file ) or die "Couldn't open $summary_file";
	$summary_data = <F>;
	close F;
	open( F, $detail_file ) or die "Couldn't open $detail_file";
	$detail_data = <F>;
	close F;
}

use_ok('Finance::Bank::Wachovia::Credit');
use Finance::Bank::Wachovia::DataObtainer::WWW;
my $do = Finance::Bank::Wachovia::DataObtainer::WWW->new();
$do->cached_content->{'summary'} = $summary_data;
$do->cached_content->{'details'}{'1234123412341234'} = $detail_data;

my $account = Finance::Bank::Wachovia::Credit->new(
	number			=> $account_num,
	data_obtainer	=> $do, # this is necessary only when testing
);

isa_ok( $account, 'Finance::Bank::Wachovia::Credit' );
is( $account->name(), 'visa platinum', 'name' );
is( $account->number(), '1234123412341234' );
is( $account->type(), 'mbna', 'type' );
isa_ok( $account->type('saving'), 'Finance::Bank::Wachovia::Credit', 'tests attribute set behavior' );
is( $account->type(), 'saving', 'confirms attribute set behavior' );

is( $account->balance, '1718.70', 'balance' );
is( $account->balance, $account->current_balance, 'balance = current_balance' );
is( $account->available_credit, '3781.00', 'available_credit' );
is( $account->limit, '5500.00', 'limit' );

