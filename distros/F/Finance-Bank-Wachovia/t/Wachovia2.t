use strict;
use Test::More tests => 18;

use_ok('Finance::Bank::Wachovia');

my $summary_file = 'data/bank_summary2.html';
my $detail_file  = 'data/bank_transactions.html';
my $summary_data;
my $detail_data;
my @account_nums = ( '1111111111111', '2222222222222', '1234123412341234' );

{
local $/ = undef;
open( F, $summary_file ) or die "Couldn't open $summary_file";
$summary_data = <F>;
close F;
open( F, $detail_file ) or die "Couldn't open $detail_file";
$detail_data = <F>;
close F;
}
my $wachovia = Finance::Bank::Wachovia->new(
	customer_access_number	=> '123456789',
	pin						=> '1234',
	code_word				=> 'blah'
);

my $wachovia2 = Finance::Bank::Wachovia->new(
	user_id		=> 'foo',
	password	=> 'bar'
);

is( $wachovia->customer_access_number, '123456789', 'customer_access_number works' );
is( $wachovia->pin, '1234', 'pin works' );
is( $wachovia->code_word, 'blah', 'code_word works' ); 
is( $wachovia2->user_id, 'foo', 'user_id works' );
is( $wachovia2->password, 'bar', 'password works' );

my $do = $wachovia->data_obtainer;
$do->cached_content->{'summary'}					= $summary_data;
$do->cached_content->{'details'}{$account_nums[1]}	= $detail_data;

my @account_names = $wachovia->account_names();
my @account_numbers = $wachovia->account_numbers();
my @account_balances = $wachovia->account_balances();

is( $account_numbers[0], $account_nums[0], 'account_numbers() worked 0' );
is( $account_numbers[1], $account_nums[1], 'account_numbers() worked 1' );
is( $account_numbers[2], $account_nums[2], 'account_numbers() worked 2' );

is( $account_names[0], 'free ckg', 'account_names() worked 0' );
is( $account_names[1], 'personal sav', 'account_names() worked 1' );
is( $account_names[2], 'visa platinum', 'account_names() worked 2' );

is( $account_balances[0], '611.22', 'account_balances() worked 0' );
is( $account_balances[1], '1100.98', 'account_balances() worked 1' );
is( $account_balances[2], '1718.70', 'account_balances() worked 2' );

isa_ok( $wachovia->account($account_nums[0]), 'Finance::Bank::Wachovia::Account' );
isa_ok( $wachovia->account($account_nums[1]), 'Finance::Bank::Wachovia::Account' );
isa_ok( $wachovia->account($account_nums[2]), 'Finance::Bank::Wachovia::Credit' );

# account()->balance will be alias for available_balance



