use strict;
use Test::More tests => 14;

use_ok('Finance::Bank::Wachovia');

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
$do->cached_content->{'summary'}				= $summary_data;
$do->cached_content->{'details'}{$account_num}	= $detail_data;

my @account_names = $wachovia->account_names();
my @account_numbers = $wachovia->account_numbers();
my @account_balances = $wachovia->account_balances();

is( $account_numbers[0], $account_num, 'account_numbers() worked' );
is( $account_names[0], 'exp access', 'account_names() worked' );
is( $account_balances[0], '2087.72', 'account_balances() worked' );
isa_ok( $wachovia->account($account_num), 'Finance::Bank::Wachovia::Account' );

# account()->balance will be alias for available_balance

# or use the account object 
my $checkings = $wachovia->account($account_num);
is( $checkings->name, 'exp access', 'account() 1' );
is( $checkings->number, $account_num, 'account() 2' );
is( $checkings->balance, '2087.72', 'account() 3' );
is( $checkings->transactions->[0]->date, '11/17/2004', 'account() 4' );


