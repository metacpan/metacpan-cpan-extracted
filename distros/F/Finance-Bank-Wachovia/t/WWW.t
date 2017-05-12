use Test::More tests => 16;
use strict;

use_ok('Finance::Bank::Wachovia::DataObtainer::WWW');


my $summary_file = 'data/bank_summary.html';
my $detail_file  = 'data/bank_transactions.html';
my $summary_data;
my $detail_data;
my $account_num = '1234567891234';

my $do = Finance::Bank::Wachovia::DataObtainer::WWW->new();

isa_ok( $do, 'Finance::Bank::Wachovia::DataObtainer::WWW' );

# NOTE TO PEOPLE WANTING PURER TESTS!!!!
# By filling in these values with your own account info, this test will 
# run (and hopefully pass) using actual data gleaned from the wachovia website.
my %login_info = (
	can	=> '', #customer access number
	pin	=> '', #4 digit pin number
	codeword	=> '', # figure it out
);

if( $login_info{'CAN'} ){
	$do->login(%login_info); # initial scrape
}
else{
	{
		local $/ = undef;
		open( F, $summary_file ) or die "Couldn't open $summary_file";
		$summary_data = <F>;
		close F;
		open( F, $detail_file ) or die "Couldn't open $detail_file";
		$detail_data = <F>;
		close F;
	}
	$do->cached_content->{'summary'}				= $summary_data;
	$do->cached_content->{'details'}{$account_num}	= $detail_data;
}

my $summary = $do->get_summary_content();
ok( $summary =~ /RelationshipSummary/, "looks like we got summary ok" )
	or diag "Didn't get summary, got this instead:\n$summary";

my @nums = $do->get_account_numbers();
ok( @nums > 0, "we got at least one account number (@nums)");

my $detail = $do->get_detail_content( $nums[0] ); 
ok( $detail =~ /ALL TRANSACTIONS/, "looks like we got details ok" )
	or diag "Didn't get details, got this instead:\n$detail";


my $bal = $do->get_account_available_balance($nums[0]);
ok( $bal =~ /\d+\.\d{2}/, "we got an available balance ($bal)" )
	or diag "Got: $bal";

my $name = $do->get_account_name($nums[0]);
ok( $name ne '', "we got an account name ($name)" );

my $type = $do->get_account_type($nums[0]);
ok( $type ne '', "we got an account type ($type)" );

$bal = $do->get_account_posted_balance($nums[0]); # requires additional scrape
ok( $bal =~ /\d+\.\d{2}/, "we got a posted balance ($bal)" );

my $trans = $do->get_account_transactions($nums[0]); # requires additional scrape for each new account number used
ok( scalar @$trans > 0, "we got some transactions (".scalar(@$trans).")");

ok( $trans->[0]->{date} =~ m|^(\d\d/\d\d/\d{4})$|, "looks like transactions worked ($1)" );



$do = Finance::Bank::Wachovia::DataObtainer::WWW->new();
$do->user_id( 'foo' );
$do->password( 'bar' );
$do->customer_access_number( '4321' );
$do->pin('1234');
$do->code_word('baz');

is( $do->user_id(), 'foo', 'user_id works' );
is( $do->password(), 'bar', 'password works' );
is( $do->customer_access_number(), '4321', 'customer_access_number works' );
is( $do->pin, '1234', 'pin works' );
is( $do->code_word, 'baz', 'code_word works' );
