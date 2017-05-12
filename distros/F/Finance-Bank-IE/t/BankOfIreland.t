#!perl
use strict;
use warnings;

use Test::More tests => 15;

use Test::MockModule;

use lib qw( t/lib );

use Test::Util;
use Test::MockBank::BankOfIreland;

$| = 1;

our $lwp_useragent_mock;

BEGIN {
    $lwp_useragent_mock = new Test::MockModule( 'LWP::UserAgent' );
    use_ok( "Finance::Bank::IE::BankOfIreland" );
}

my $config = Test::Util::getconfig( 'BOI' );
my $live = 1;
if ( !$config ) {
    # our fake config
    $config = {
               user => '123456',
               pin => '123456',
               contact => '1234',
               dob => '01/01/1970',
              };

    # fake bank server
    $lwp_useragent_mock->mock( 'simple_request',
                               \&Test::MockBank::simple_request );
    $live = 0;
} else {
    die "probably not safe to test on live site at present";
}

Test::MockBank->globalstate( 'config', $config );

# check_balance()
Finance::Bank::IE::BankOfIreland->reset and
  Test::MockBank->globalstate( 'loggedin', 0 );
my @accounts;
ok( @accounts = Finance::Bank::IE::BankOfIreland->check_balance( $config ),
    "retrieve balances from BoI" );

Test::MockBank->globalstate( 'loggedin', 0 );
ok( @accounts = Finance::Bank::IE::BankOfIreland->check_balance(),
    "cached config (check_balances)" );
my $testaccount = shift @accounts;

Finance::Bank::IE::BankOfIreland->reset and
  Test::MockBank->globalstate( 'loggedin', 0 );
Test::MockBank->on_page( 'https://www.365online.com/online365/spring/accountSummary?execution=e2s1', undef );
eval {
    @accounts = Finance::Bank::IE::BankOfIreland->check_balance( $config );
};
ok( !@accounts, "handle accounts page failure (1)" );
Test::MockBank->on_page();

# account_details()
Finance::Bank::IE::BankOfIreland->reset and
    Test::MockBank->globalstate( 'loggedin', 0 );
ok( Finance::Bank::IE::BankOfIreland->account_details( $testaccount->nick, $config ), "get details for BoI account " . $testaccount->nick );

Test::MockBank->globalstate( 'loggedin', 0 );
ok( Finance::Bank::IE::BankOfIreland->account_details( $testaccount->nick ),
    "cached_config (account_details)" );

# list_beneficiaries()
my $benes;
Finance::Bank::IE::BankOfIreland->reset and
  Test::MockBank->globalstate( 'loggedin', 0 );
ok( $benes = Finance::Bank::IE::BankOfIreland->list_beneficiaries( $testaccount, $config ), "get beneficiaries for BoI account " . $testaccount->nick );

Test::MockBank->globalstate( 'loggedin', 0 );
ok( $benes = Finance::Bank::IE::BankOfIreland->list_beneficiaries( $testaccount ), "get beneficiaries for BoI account " . $testaccount->nick . " (cached config)" );

my $testbeneficiary;
( $testbeneficiary ) = grep { $_->{status} eq 'Active' } @{$benes};
my $ambiguousbeneficiary;
my %beneficiaries;
for my $beneficiary ( @{$benes} ) {
    $beneficiaries{$beneficiary->nick} = ( $beneficiaries{$beneficiary->nick} || 0 ) + 1;
    $beneficiaries{$beneficiary->account_no} = ( $beneficiaries{$beneficiary->account_no} || 0 ) + 1;
}
( $ambiguousbeneficiary ) = grep { $beneficiaries{$_} > 1 } ( keys %beneficiaries );

# no live test for funds transfer, for obvious reasons
SKIP:
{
    my $FUNDS_TRANSFER_TESTS = 6;

    skip "funds transfer not tested against live site", $FUNDS_TRANSFER_TESTS
      if $live;
    skip "no beneficiaries available to test", $FUNDS_TRANSFER_TESTS
      if !$testbeneficiary;

    # keep this segment honest
    my $test_builder = Test::More->builder();
    my $first_funds_transfer_test = $test_builder->current_test();

    Finance::Bank::IE::BankOfIreland->reset() and
        Test::MockBank->globalstate( 'loggedin', 0 );
    ok( Finance::Bank::IE::BankOfIreland->funds_transfer( $testaccount->nick, $testbeneficiary->nick, 1, $config ), "funds transfer" );

    Test::MockBank->globalstate( 'loggedin', 0 );
    ok( Finance::Bank::IE::BankOfIreland->funds_transfer( $testaccount->nick, $testbeneficiary->nick, 1 ), "cached config (funds_transfer)" );

    ok( Finance::Bank::IE::BankOfIreland->funds_transfer( $testaccount, $testbeneficiary->nick, 1 ), "funds_transfer accepts an Account object as a source" );

    ok( Finance::Bank::IE::BankOfIreland->funds_transfer( $testaccount, $testbeneficiary, 1 ), "funds_transfer accepts an Account object as a destination" );

    eval {
        Finance::Bank::IE::BankOfIreland->funds_transfer( $testaccount, "bogus", 1 );
    };
    ok( $@ =~ /^Unable to find bogus in list of accounts/, "funds_transfer fails to transfer to account not in beneficiaries list" );

  SKIP: {
        skip "no ambiguous beneficiaries", 1 unless $ambiguousbeneficiary;
        eval {
            Finance::Bank::IE::BankOfIreland->funds_transfer( $testaccount, $ambiguousbeneficiary, 1 );
        };
        ok( $@ =~ /^Ambiguous destination account/, "funds_transfer fails if destination is ambiguous" );
    }

    my $actual_funds_transfer_tests = $test_builder->current_test() - $first_funds_transfer_test;
    if ( $actual_funds_transfer_tests != $FUNDS_TRANSFER_TESTS ) {
        die "\$FUNDS_TRANSFER_TESTS needs to be updated to $actual_funds_transfer_tests\n";
    }
}

my $testbene;
for my $bene ( @{$benes} ) {
    if ( $bene->{status} eq "Inactive" ) {
        $testbene = $bene;
        last;
    }
}

# _scrub_page
{
    local $/ = undef;
    open( my $unscrubbed, "<", "data/BankOfIreland/unscrubbed" );
    my $content = <$unscrubbed>;
    my $scrubbed = Finance::Bank::IE::BankOfIreland->_scrub_page( $content );
    ok( $scrubbed, "_scrub_page" );
}
