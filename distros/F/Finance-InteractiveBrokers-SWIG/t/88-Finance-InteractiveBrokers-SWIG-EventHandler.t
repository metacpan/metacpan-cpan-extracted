#!perl -T
#
#   Finance::InteractiveBrokers::SWIG - Tests for EventHandler module
#
#   Copyright (c) 2010-2014 Jason McManus
#

use Data::Dumper;
use Test::More;     # Test count calculated at end with done_testing()
use strict;
use warnings;
$|=1;

# Ours
use Finance::InteractiveBrokers::API;           # module prerequisite
use Finance::InteractiveBrokers::SWIG::IBAPI;   # already tested
use lib 't/inc';                                # for TestEventHandler.pm

###
### Vars
###

use vars qw( $TRUE $FALSE $VERSION );

$VERSION = '0.13';
*TRUE    = \1;
*FALSE   = \0;

my $obj;
my $api_version = Finance::InteractiveBrokers::SWIG::IBAPI::api_version();

###
### Tests
###

BEGIN {
    use_ok( 'Finance::InteractiveBrokers::SWIG::EventHandler' )
        || print "Bail out!";
}

##########################################################################
# Test: Make sure we can't instantiate the base class
# Expected: FAIL
eval {
    $obj = Finance::InteractiveBrokers::SWIG::EventHandler->new();
};
is( $obj, undef,                            'Object is correctly undef' );
like( $@, qr/is an abstract base class/,    'Requires subclass properly' );

##########################################################################
# Test: Require our subclass
# Expected: PASS
require_ok( 'TestEventHandler.pm' );

##########################################################################
# Test: Instantiate an event handler
# Expected: PASS
isa_ok( $obj = TestEventHandler->new(),     'TestEventHandler' );
isa_ok( $obj,             'Finance::InteractiveBrokers::SWIG::EventHandler' );
is( $obj->api_version, $api_version,        'api_version()' );
isa_ok( $obj->_api,                     'Finance::InteractiveBrokers::API' );

##########################################################################
# Test: Test the event lists match the override list
# Expected: PASS
my @events   = $obj->_api->events();
my @override = $obj->override();
is_deeply( \@events, \@override,            'override() correct' );

##########################################################################
# Test: Try to call a couple of random method names
# Expected: FAIL
for my $event ( qw( kjwrlkajs opixzpcoi wnanmf ) )
{
    eval {
        $obj->$event();
    };
    like( $@, qr/received invalid event $event/, "invalid event: $event" );
}

##########################################################################
# Test: Test all the IB API calls can be called
# Expected: PASS
for my $event ( @events )
{
    # Try to call every event as method; they all output TAP
    $obj->$event();
}

###
### Output our calculated test count
###
done_testing( 9 + 3 + scalar( @events ) );

# Always return true
1;

__END__
