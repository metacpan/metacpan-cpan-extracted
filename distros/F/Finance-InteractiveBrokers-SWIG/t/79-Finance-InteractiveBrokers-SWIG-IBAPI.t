#!perl -T
#
#   POE::Component::Client::InteractiveBrokers - Tests for SWIG module
#
#   Copyright (c) 2010-2014 Jason McManus
#

use Data::Dumper;
use Test::More;
use strict;
use warnings;

# Ours.
use Finance::InteractiveBrokers::API;

###
### Vars
###

use vars qw( $TRUE $FALSE $VERSION );

$VERSION = '0.13';
*TRUE    = \1;
*FALSE   = \0;

my $obj;
my( $api_version, $build_time );

###
### Tests
###

# 1 Test
BEGIN {
    use_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI' ) || print "Bail out!";
}

################################################################
# 3 Tests: Can instantiate IBAPI::IBAPIClient (through .so)
# Expected: PASS
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient', 'new' );
isa_ok( $obj = Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient->new(),
            'Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient' );

# Check our API versions are equal
is( $api_version = Finance::InteractiveBrokers::SWIG::IBAPI::api_version(),
    $obj->version(),            'runtime and static versions are equal' );
diag( "API Version: $api_version" );

# Check our build times are equal
is( $build_time = Finance::InteractiveBrokers::SWIG::IBAPI::build_time(),
    $obj->build_time(),         'pm and library build times are equal' );
#diag( "Build Time: ", scalar localtime( $build_time ) );

################################################################
# 46 Tests: all expected subs in all classes exist
# Expected: PASS
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI', 'TIEHASH' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI', 'CLEAR' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI', 'FIRSTKEY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI', 'NEXTKEY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI', 'FETCH' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI', 'STORE' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI', 'this' );

# Already tested
#can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ComboLeg', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ComboLeg', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ComboLeg', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ComboLeg', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::UnderComp', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::UnderComp', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::UnderComp', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::UnderComp', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Contract', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Contract', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Contract', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Contract', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ContractDetails', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ContractDetails', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ContractDetails', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ContractDetails', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Order', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Order', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Order', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Order', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::OrderState', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::OrderState', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::OrderState', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::OrderState', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Execution', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Execution', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Execution', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::Execution', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ExecutionFilter', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ExecutionFilter', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ExecutionFilter', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ExecutionFilter', 'ACQUIRE' );

can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ScannerSubscription', 'new' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ScannerSubscription', 'DESTROY' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ScannerSubscription', 'DISOWN' );
can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::ScannerSubscription', 'ACQUIRE' );

if( $api_version >= 9.67 )
{
    can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::CommissionReport', 'new' );
    can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::CommissionReport', 'DESTROY' );
    can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::CommissionReport', 'DISOWN' );
    can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::CommissionReport', 'ACQUIRE' );
}

################################################################
# Test: all methods callable
# Expected: PASS
my @methods = Finance::InteractiveBrokers::API->new(
        version => Finance::InteractiveBrokers::SWIG::IBAPI::api_version()
)->methods();
for my $method ( @methods )
{
    can_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient', $method );
}

################################################################
# Test: no event methods present
# Expected: FAIL
my @events  = Finance::InteractiveBrokers::API->new(
        version => Finance::InteractiveBrokers::SWIG::IBAPI::api_version()
)->events();
for my $event ( @events )
{
    my $can =
        "Finance::InteractiveBrokers::SWIG::IBAPI::IBAPIClient"->can( $event );
    is( $can, undef, "F::IB::SWIG::IBAPI::IBAPIClient::$event not present" );
}



###
### TODO: Optional live tests
###

###
### Output the calculated test count
###
done_testing( 1 +
              4 +
              46 +
              ( ( $api_version >= 9.67 ) ? 4 : 0 ) +
              scalar( @methods ) +
              scalar( @events ) );

# Always return true
1;

__END__
