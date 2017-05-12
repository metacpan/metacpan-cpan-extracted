#!perl -T
#
#   Finance::InteractiveBrokers::API - Tests for main module
#
#   Copyright (c) 2010-2013 Jason McManus
#

use Data::Dumper;
use Test::More;
use strict;
use warnings;

###
### Vars
###

use vars qw( $TRUE $FALSE $VERSION );
BEGIN {
    $VERSION = '0.04';
}

*TRUE      = \1;
*FALSE     = \0;

my( $API, $EVENTS );

my $obj;

###
### Tests
###

# Uncomment for use tests
BEGIN {
    use_ok( 'Finance::InteractiveBrokers::API' ) || print "Bail out!";
}

################################################################
# Test: Class method 'api_versions' works
# Expected: PASS
my @junk1 = Finance::InteractiveBrokers::API::api_versions();
cmp_ok( @junk1, '>', 0,                 'Class method api_versions() works' );
my @junk2 = Finance::InteractiveBrokers::API::versions();
cmp_ok( @junk2, '>', 0,                 'Class method alias versions() works' );
is_deeply( \@junk1, \@junk2,            'Both return same values' );

my @known_apis = sort keys( %$API );
is_deeply( \@junk1, \@known_apis,       'All known APIs accounted for' );

################################################################
# Test: Invalid version fails
# Expected: FAIL
eval {
    $obj = Finance::InteractiveBrokers::API->new( version => 'froofroo' );
};
is( $obj, undef,                        'Object is correctly undef' );
like( $@, qr/^API version 'froofroo' is unknown/,
                                        'Invalid version fails as expected' );

################################################################
# Test: No version passes, defaults to 9.64
# Expected: PASS
isa_ok( $obj = Finance::InteractiveBrokers::API->new(),
                                        'Finance::InteractiveBrokers::API' );

for my $api_ver ( sort keys( %{ $API } ) )
{
    ################################################################
    # Test: Specific version passed
    # Expected: PASS
    isa_ok( $obj = Finance::InteractiveBrokers::API->new( version => $api_ver ),
                                         'Finance::InteractiveBrokers::API' );

    ################################################################
    # Tests: Rest of object functions correctly
    # Expected: PASS
    is( $obj->api_version(), $api_ver,            "api_version() = $api_ver" );
    is( $obj->version(), $api_ver,                "version() = $api_ver" );
    is( my @meths = $obj->methods(), scalar( @{ $API->{$api_ver} } ),
                                "methods() == " . @{ $API->{$api_ver} } );
    is( my @evs = $obj->events(),    scalar( @{ $EVENTS->{$api_ver} } ),
                                "methods() == " . @{ $EVENTS->{$api_ver} } );
    is( my @all = $obj->everything(), scalar( @meths ) + scalar( @evs ),
                                                        "everything()" );

    for my $method ( @{ $API->{$api_ver} } )
    {
        is( $obj->is_method( $method ), $TRUE, "is_method( $method ) == 1" );
        is( $obj->in_api( $method ),    $TRUE, "in_api( $method ) == 1" );
    }
    for my $event ( @{ $EVENTS->{$api_ver} } )
    {
        is( $obj->is_event( $event ), $TRUE, "is_event( $event ) == 1" );
        is( $obj->in_api( $event ),   $TRUE, "in_api( $event ) == 1" );
    }

    is( $obj->is_method( 'akiw' ), $FALSE, "is_method( akiw ) invalid" );
    is( $obj->is_event( 'AJRK' ),  $FALSE, "is_event( AJRK ) invalid" );
    is( $obj->in_api( 'GOAR' ),    $FALSE, "in_api( GOAR ) invalid" );

    is( $obj->is_method( '' ),  $FALSE,    "is_method( '' ) invalid" );
    is( $obj->is_event( '' ),   $FALSE,    "is_event( '' ) invalid" );
    is( $obj->in_api( '' ),     $FALSE,    "in_api( '' ) invalid" );

    is( $obj->is_method(),      $FALSE,    "is_method() invalid" );
    is( $obj->is_event(),       $FALSE,    "is_event() invalid" );
    is( $obj->in_api(),         $FALSE,    "in_api() invalid" );
}

# Say goodbye to the bad guy.
done_testing();

# Always return true
1;

# END

###
# API and event names

BEGIN {
    $API->{'9.64'} = [
        qw(
            processMessages
            setSelectTimeout
            eConnect
            eDisconnect
            isConnected
            reqCurrentTime
            serverVersion
            setServerLogLevel
            checkMessages
            TwsConnectionTime
            reqMktData
            cancelMktData
            calculateImpliedVolatility
            cancelCalculateImpliedVolatility
            calculateOptionPrice
            cancelCalculateOptionPrice
            placeOrder
            cancelOrder
            reqOpenOrders
            reqAllOpenOrders
            reqAutoOpenOrders
            reqIds
            exerciseOptions
            reqAccountUpdates
            reqExecutions
            reqContractDetails
            reqMktDepth
            cancelMktDepth
            reqNewsBulletins
            cancelNewsBulletins
            reqManagedAccts
            requestFA
            replaceFA
            reqHistoricalData
            cancelHistoricalData
            reqScannerParameters
            reqScannerSubscription
            cancelScannerSubscription
            reqRealTimeBars
            cancelRealTimeBars
            reqFundamentalData
            cancelFundamentalData
        ),
    ];
    $API->{'9.65'} = $API->{'9.64'};
    $API->{'9.66'} = [
        @{ $API->{'9.65'} },
        qw(
            reqMarketDataType
            reqGlobalCancel
        ),
    ];
    $API->{'9.67'} = $API->{'9.66'};

    $EVENTS->{'9.64'} = [ qw(
            winError
            error
            connectionClosed
            currentTime
            tickPrice
            tickSize
            tickOptionComputation
            tickGeneric
            tickString
            tickEFP
            tickSnapshotEnd
            orderStatus
            openOrder
            openOrderEnd
            nextValidId
            updateAccountValue
            updatePortfolio
            updateAccountTime
            updateNewsBulletin
            contractDetails
            contractDetailsEnd
            bondContractDetails
            execDetails
            execDetailsEnd
            updateMktDepth
            updateMktDepthL2
            managedAccounts
            receiveFA
            historicalData
            scannerParameters
            scannerData
            scannerDataEnd
            realtimeBar
            fundamentalData
            deltaNeutralValidation
            accountDownloadEnd
        ),
    ];
    $EVENTS->{'9.65'} = $EVENTS->{'9.64'};
    $EVENTS->{'9.66'} = [
        @{ $EVENTS->{'9.65'} },
        qw(
            marketDataType
        ),
    ];
    $EVENTS->{'9.67'} = [
        @{ $EVENTS->{'9.66'} },
        qw(
            commissionReport
        ),
    ];
}


__END__
