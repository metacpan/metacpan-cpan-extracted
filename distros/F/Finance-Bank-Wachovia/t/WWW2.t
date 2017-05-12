use Test::More tests => 15;
use strict;

use_ok('Finance::Bank::Wachovia::DataObtainer::WWW');


my $summary_file = 'data/bank_summary2.html';
my $credit_file  = 'data/credit_summary.html';
my $summary_data;
my $credit_data;
my $account_num = '1234123412341234';

my $do = Finance::Bank::Wachovia::DataObtainer::WWW->new();

isa_ok( $do, 'Finance::Bank::Wachovia::DataObtainer::WWW' );

{
	local $/ = undef;
	open( F, $summary_file ) or die "Couldn't open $summary_file";
	$summary_data = <F>;
	close F;
	open( F, $credit_file ) or die "Couldn't open $credit_file";
	$credit_data = <F>;
	close F;
}
$do->cached_content->{'summary'}				= $summary_data;
$do->cached_content->{'details'}{$account_num}	= $credit_data;

my $summary = $do->get_summary_content();
ok( $summary =~ /RelationshipSummary/, "looks like we got summary ok" )
	or diag "Didn't get summary, got this instead:\n$summary";

my @nums = $do->get_account_numbers();
ok( @nums == 3, "we got 3 account nums");

my $detail = $do->get_detail_content( $nums[2] ); 
ok( $detail =~ /VISA PLATINUM/, "looks like we got credit ok" )
	or diag "Didn't get credit, got this instead:\n$detail";


my $bal = $do->get_account_available_balance( $nums[2] );
is( $bal, '1718.70', "we got an available balance ($bal)" )
	or diag "Got: $bal";

my $name = $do->get_account_name($nums[2]);
is( $name , 'visa platinum', "we got an account name ($name)" );

my $type = $do->get_account_type($nums[2]);
is( $type, 'mbna', "we got an account type ($type)" );

my $limit = $do->get_credit_account_limit($nums[2]); # requires additional scrape
is( $limit, '5500.00', "get_credit_account_limit" );

my $avail = $do->get_credit_account_available_credit($nums[2]); # requires additional scrape for each new account number used
is( $avail, '3781.00', "get_credit_account_available_credit");

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
