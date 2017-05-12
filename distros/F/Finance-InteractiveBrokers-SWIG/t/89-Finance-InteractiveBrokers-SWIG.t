#!perl -T
#
#   Finance::InteractiveBrokers::SWIG - Tests for main module
#
#   Copyright (c) 2010-2014 Jason McManus
#

use Data::Dumper;
use Test::More;     # Tests calculated at end with done_testing()
use strict;
use warnings;
$|=1;

# Ours
use Finance::InteractiveBrokers::SWIG::IBAPI;   # already tested
use lib 't/inc';
use TestEventHandler;
use TestUtil;

###
### Vars
###

use vars qw( $TRUE $FALSE $VERSION );

$VERSION = '0.13';
*TRUE    = \1;
*FALSE   = \0;

my( $obj, $handler );
my $api_version = Finance::InteractiveBrokers::SWIG::IBAPI::api_version();

# Has been tested before this
$handler = TestEventHandler->new( api_version => '9.64' );

###
### Tests
###

BEGIN {
    use_ok( 'Finance::InteractiveBrokers::SWIG' ) || print "Bail out!";
}

##########################################################################
# Test: Don't pass a handler
# Expected: FAIL
eval {
    $obj = Finance::InteractiveBrokers::SWIG->new();
};
is( $obj, undef,                              'Object undef' );
like( $@, qr/handler is a required argument/, 'No handler passed' );


##########################################################################
# Test: Pass an invalid handler
# Expected: FAIL
eval {
    $obj = Finance::InteractiveBrokers::SWIG->new(
        handler => TestUtil->new()
    );
};
is( $obj, undef,                               'Object undef' );
like( $@, qr/handler .*? must be subclass of/, 'Invalid handler passed' );


##########################################################################
# Test: Make sure we can instantiate the object (and thus, link, etc)
# Expected: PASS
isa_ok( $obj = Finance::InteractiveBrokers::SWIG->new(
          handler     => $handler,
          __TESTING__ => $TRUE,
      ), 'Finance::InteractiveBrokers::SWIG' );

##########################################################################
# Test: Object Accessors
# Expected: PASS
isa_ok( $obj->_handler,    'Finance::InteractiveBrokers::SWIG::EventHandler' );
isa_ok( $obj->_handler,                          'TestEventHandler' );
isa_ok( $obj->_api,                       'Finance::InteractiveBrokers::API' );
is( $obj->api_version, $api_version,             'api_version()' );

##########################################################################
# Test: Test the methods list matches the api_methods() list
# Expected: PASS
my @methods     = $obj->_api->methods();
my @api_methods = $obj->api_methods();
is_deeply( \@methods, \@api_methods,            'api_methods() correct' );

##########################################################################
# Test: Call some invalid methods
# Expected: FAIL
for my $method ( qw( gorsplatch freen basjhdahdjh ) )
{
    eval {
        $obj->$method();
    };
    like( $@, qr/invalid method $method/, "invalid method: $method" );
}

##########################################################################
# Test: Call all valid API methods
# Expected: PASS
for my $method ( @methods )
{
    my $string = TestUtil::random_string( 6 );
    my $retval;
    eval {
        ( $retval ) = $obj->$method( $string );
    };
    unlike( $@, qr/invalid method $method/, "valid method: $method" );
    is( $string, $retval, "$method retval correct" );
}

##########################################################################
# Test: Trigger all events
# Expected: PASS
my @events = $obj->_api->events();
for my $event ( @events )
{
    # These should be delegated to TestEventHandler and output TAP
    $obj->_event_dispatcher( $event );
}

###
### Output the calculated test count
###
done_testing( 11 + 3 + ( 2 * scalar( @methods ) ) + scalar( @events ) );

# Always return true
1;

__END__
