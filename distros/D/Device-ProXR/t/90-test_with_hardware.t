##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 90-test_with_hardware.t
## Description: Test with actual hardware if the DEVICE_PROXR_TEST_PORT
##              environment variable is specified
##----------------------------------------------------------------------------
use Test::More;
use Readonly;
use Time::HiRes qw(usleep);
use Device::ProXR::RelayControl;

##--------------------------------------------------------
## Time conversion contants
##--------------------------------------------------------
## uSeconds per millisecond
Readonly::Scalar my $USECS_PER_MS => 1000;
## milliseconds per second
Readonly::Scalar my $MS_PER_SEC => 1000;
## uSeconds per second
Readonly::Scalar my $USECS_PER_SEC => $USECS_PER_MS * $MS_PER_SEC;


##--------------------------------------
## Get port from environment variable
##--------------------------------------
my $port = $ENV{DEVICE_PROXR_TEST_PORT} // qq{};

## See if environment variable was set
if ($port)
{
  ## We have a port, so run the tests
  plan tests => 10;
}
else
{
  ## We do not have a port, so skip the tests 
  plan skip_all => qq{Environment variable DEVICE_PROXR_TEST_PORT not specified};
}

##--------------------------------------
## Create object
##--------------------------------------
diag(qq{Testing using port "$port"});
my $board = new_ok(qq{Device::ProXR::RelayControl} => [port => $port]);

##--------------------------------------
## Turn on a relay
##--------------------------------------
my $resp;
$resp = $board->relay_on(1, 0);
cmp_ok(length($resp), '==', 1, qq{relay_on() response length});
cmp_ok(ord(substr($resp, 0, 1)), '==', 0x55, qq{relay_on() response 0x55});

usleep(500 * $USECS_PER_MS);

##--------------------------------------
## Turn off a relay
##--------------------------------------
$resp = $board->relay_off(1, 0);
cmp_ok(length($resp), '==', 1, qq{relay_off() response length});
cmp_ok(ord(substr($resp, 0, 1)), '==', 0x55, qq{relay_off() response 0x55});

usleep(500 * $USECS_PER_MS);

##--------------------------------------
## Turn on all relays
##--------------------------------------
$resp = $board->all_on();
cmp_ok(length($resp), '==', 1, qq{all_on() response length});
cmp_ok(ord(substr($resp, 0, 1)), '==', 0x55, qq{all_on() response 0x55});

usleep(500 * $USECS_PER_MS);

##--------------------------------------
## Get bank status
##--------------------------------------
$resp = $board->bank_status(3);
cmp_ok($resp, '==', 0xFF, qq{bank_status() response 0xFF});

usleep(500 * $USECS_PER_MS);

##--------------------------------------
## Turn off all relays
##--------------------------------------
$resp = $board->all_off();
cmp_ok(length($resp), '==', 1, qq{all_off() response length});
cmp_ok(ord(substr($resp, 0, 1)), '==', 0x55, qq{all_off() response 0x55});
