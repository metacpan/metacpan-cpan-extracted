#!perl
use warnings;
use strict;

use Test::More tests => 36;

use Cwd;
use Test::MockModule;
use Data::Dumper;

use lib qw( t/lib );

use Test::Util;

$| = 1;

my $MODULE_UNDER_TEST;
BEGIN {
    $MODULE_UNDER_TEST = Test::Util::setup();
}

our $lwp_useragent_mock;
our $www_mechanize_mock;

BEGIN {
    $lwp_useragent_mock = new Test::MockModule( 'LWP::UserAgent' );
    $www_mechanize_mock = new Test::MockModule( 'WWW::Mechanize' );
    use_ok( "Finance::Bank::IE::$MODULE_UNDER_TEST" );
}

my $live = 1;
my $config = Test::Util::getconfig( $MODULE_UNDER_TEST );
if ( !$config ) {
    # our fake config
    $config = {
               user => '0123456789',
               password => 'password',
               pin => '123456',
              };

    # this is our fake bank server
    $lwp_useragent_mock->mock( 'simple_request', \&Test::MockBank::simple_request );

    $live = 0;
} else {
    print "# Running live tests\n" if $ENV{DEBUG};
}
Test::MockBank->globalstate( 'config', $config );

my @accounts = Finance::Bank::IE::PTSB->check_balance( $config );
ok( @accounts, "can retrieve accounts" );
isa_ok( $accounts[0], "Finance::Bank::IE::PTSB::Account", "account" );
ok( $accounts[0]->{account_no}, "account has an account number" );

my $testaccount = $accounts[0];

# reset state
ok( Finance::Bank::IE::PTSB->reset, "can reset object" ) and
    Test::MockBank->globalstate( 'loggedin', 0 );

my ( @details ) = Finance::Bank::IE::PTSB->account_details( $testaccount->account_no, $config );
ok( @details, "can fetch details" );

( @details ) = Finance::Bank::IE::PTSB->account_details( undef, $config );
ok( !@details, "no account details if no account specified" );

( @details ) = Finance::Bank::IE::PTSB->account_details( 'bogus', $config );
ok( !@details, "no account details if invalid account specified" );

# list_beneficiaries
Finance::Bank::IE::PTSB->reset and
    Test::MockBank->globalstate( 'loggedin', 0 );
my $beneficiaries = Finance::Bank::IE::PTSB->list_beneficiaries( $testaccount, $config );
ok( $beneficiaries, "can list beneficiaries" );

$beneficiaries = Finance::Bank::IE::PTSB->list_beneficiaries();
ok( !$beneficiaries, "no beneficiaries if no account specified" );

$beneficiaries = Finance::Bank::IE::PTSB->list_beneficiaries( $testaccount->account_no );
ok( $beneficiaries, "can pass account as account number" );

# add_beneficiary
my @new_beneficiary = ( '99999999', '999999', 'An account', 'A nickname' );
Finance::Bank::IE::PTSB->reset and
    Test::MockBank->globalstate( 'loggedin', 0 );

# insufficient fields
ok( !Finance::Bank::IE::PTSB->add_beneficiary( $testaccount, $new_beneficiary[0] ), "add_beneficiary fails unless enough fields are given" );

my $beneficiary_add;
SKIP: {
    skip "page format changed", 1 if 1;
    ok( $beneficiary_add = Finance::Bank::IE::PTSB->add_beneficiary( $testaccount, @new_beneficiary, $config ), "add_beneficiary adds a beneficiary" );
}

my $benes;
Finance::Bank::IE::PTSB->reset and
    Test::MockBank->globalstate( 'loggedin', 0 );
ok( $benes = Finance::Bank::IE::PTSB->list_beneficiaries( $testaccount, $config ), "get beneficiaries for PTSB account '" . $testaccount->nick . "'" );

my $testbeneficiary;
( $testbeneficiary ) = grep { $_->{status} eq 'Active' } @{$benes};
my $ambiguousbeneficiary;
my %beneficiaries;
for my $beneficiary ( @{$benes} ) {
    $beneficiaries{$beneficiary->nick} = ( $beneficiaries{$beneficiary->nick} || 0 ) + 1;
    $beneficiaries{$beneficiary->account_no} = ( $beneficiaries{$beneficiary->account_no} || 0 ) + 1;
}
( $ambiguousbeneficiary ) = grep { $beneficiaries{$_} > 1 } ( keys %beneficiaries );

# funds transfer
SKIP:
{
    my $FUNDS_TRANSFER_TESTS = 6;

    # no live tests!
    skip "funds transfer not tested against live site", $FUNDS_TRANSFER_TESTS
        if $live;
    skip "no beneficiaries are available to test", $FUNDS_TRANSFER_TESTS
        if !$testbeneficiary;

    skip "currently broken", $FUNDS_TRANSFER_TESTS
        if 1;

    # keep this segment honest
    my $test_builder = Test::More->builder();
    my $first_funds_transfer_test = $test_builder->current_test();

    Finance::Bank::IE::PTSB->reset and
      Test::MockBank::globalstate('loggedin', 0);
    ok( Finance::Bank::IE::PTSB->funds_transfer( $testaccount->nick, $testbeneficiary->nick, 1, $config ), "funds transfer" );

    Test::MockBank->globalstate( 'loggedin', 0 );
    ok( Finance::Bank::IE::PTSB->funds_transfer( $testaccount->nick, $testbeneficiary->nick, 1 ), "cached config (funds_transfer)" );

    ok( Finance::Bank::IE::PTSB->funds_transfer( $testaccount, $testbeneficiary->nick, 1 ), "funds_transfer accepts an Account object as a source" );

    ok( Finance::Bank::IE::PTSB->funds_transfer( $testaccount, $testbeneficiary, 1 ), "funds_transfer accepts an Account object as a destination" );

    ok( !Finance::Bank::IE::PTSB->funds_transfer( $testaccount, "bogus", 1 ),
        "funds_transfer fails to transfer to account not in beneficiaries list" );

  SKIP: {
        skip "no ambiguous beneficiaries", 1 unless $ambiguousbeneficiary;
        ok( !Finance::Bank::IE::PTSB->funds_transfer( $testaccount, $ambiguousbeneficiary, 1 ), "funds_transfer fails if destination is ambiguous" );
    }

    my $actual_funds_transfer_tests = $test_builder->current_test() - $first_funds_transfer_test;
    if ( $actual_funds_transfer_tests != $FUNDS_TRANSFER_TESTS ) {
        die "\$FUNDS_TRANSFER_TESTS needs to be updated to $actual_funds_transfer_tests\n";
    }
}

# test use of cached config (and first make sure we /have/ cached config)
Test::MockBank->globalstate( 'loggedin', 0 );
( @details ) = Finance::Bank::IE::PTSB->account_details( $testaccount->account_no, $config );
Test::MockBank->globalstate( 'loggedin', 0 );
( @details ) = Finance::Bank::IE::PTSB->account_details( $testaccount->account_no );
ok( @details, "cached config (account_details)" );
Test::MockBank->globalstate( 'loggedin', 0 );
@accounts = Finance::Bank::IE::PTSB->check_balance();
ok( @accounts, "cached config (check_balance)" );
Test::MockBank->globalstate( 'loggedin', 0 );
$beneficiaries = Finance::Bank::IE::PTSB->list_beneficiaries( $testaccount );
ok( $beneficiaries, "cached config (list beneficiaries)" );

Finance::Bank::IE::PTSB->reset and
    Test::MockBank->globalstate( 'loggedin', 0 );
( @details ) = Finance::Bank::IE::PTSB->account_details( $testaccount->account_no, $config );
ok( @details, "can fetch details directly" );

# _scrub_page
{
    local $/ = undef;
    open( my $unscrubbed, "<", "data/PTSB/unscrubbed" );
    my $content = <$unscrubbed>;
    my $scrubbed = Finance::Bank::IE::PTSB->_scrub_page( $content );
    # checking if it really is scrubbed is performed in scrubbed.t
    ok( $scrubbed, "_scrub_page" );
}

SKIP:
{
    skip "these tests don't work against the live site", 3 if $live;

    # some failure scenarios
    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );

    # if we get a page failure, it should trip up the code but not
    # cause it to crash
    Test::MockBank->fail_on_iterations( 1 );
    @accounts = Finance::Bank::IE::PTSB->check_balance( $config );
    ok( !@accounts, "can handle page-load failure (check_balance)" );

    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->fail_on_iterations( 1 );
    ( @details ) = Finance::Bank::IE::PTSB->account_details( $testaccount, $config );
    ok( !@details, "can handle page-load failure (account_detail)" );

    # this checks the _third_party code as well
    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->fail_on_iterations( 5 );
    $beneficiaries = Finance::Bank::IE::PTSB->list_beneficiaries( $testaccount,
                                                                  $config );
    ok( !$beneficiaries, "can handle page-load failure (list_beneficiaries 1)")
        or diag Dumper($beneficiaries);

    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->fail_on_iterations( 6 );
    $beneficiaries = Finance::Bank::IE::PTSB->list_beneficiaries( $testaccount,
                                                                  $config );
    ok( !$beneficiaries, "can handle page-load failure (list_beneficiaries 2)");

    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->fail_on_iterations( 5 );
    $beneficiary_add = Finance::Bank::IE::PTSB->add_beneficiary( $testaccount, @new_beneficiary, $config );
    ok( !$beneficiary_add, "can handle page-load failure (add_beneficiary)");

    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->fail_on_iterations( 7 );
    $beneficiary_add = Finance::Bank::IE::PTSB->add_beneficiary( $testaccount, @new_beneficiary, $config );
    ok( !$beneficiary_add, "can handle page-load failure (add_beneficiary 2)");

    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->fail_on_iterations( 8 );
    $beneficiary_add = Finance::Bank::IE::PTSB->add_beneficiary( $testaccount, @new_beneficiary, $config );
    ok( !$beneficiary_add, "can handle page-load failure (add_beneficiary 2)");

    Finance::Bank::IE::PTSB->reset and
        Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->fail_on_iterations( 9 );
    $beneficiary_add = Finance::Bank::IE::PTSB->add_beneficiary( $testaccount, @new_beneficiary, $config );
    ok( !$beneficiary_add, "can handle page-load failure (add_beneficiary 2)");

    # looping login page
    Test::MockBank->fail_on_iterations( 0 );
    Test::MockBank->globalstate( 'loggedin', 0 );
    Test::MockBank->globalstate( 'loop', 1 );
    @accounts = Finance::Bank::IE::PTSB->check_balance( $config );
    ok( !@accounts, "can handle looping login page" );

    Test::MockBank->globalstate( 'loop', 0 );
}

# utterly bogus URL (mainly for coverage)
Test::MockBank->globalstate( 'loggedin', 0 );
my $return = Finance::Bank::IE::PTSB->_get( 'breakit', $config );
ok( !defined( $return ), "bogus url" ) or diag "expected undef, got $return";
$return = Finance::Bank::IE::PTSB->_get( 'breakit' );
ok( !defined( $return ), "bogus url" ) or diag "expected undef, got $return";
