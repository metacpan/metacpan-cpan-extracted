#!perl -T
use strict;
use Test::More;
use lib "t/lib";


plan tests => 5;

my $obj;

# load the module
use_ok("Device::TLSPrinter");

# check diagnostics
$obj = eval { Device::TLSPrinter->new(type => "mock") };
like( $@, '/^error: Missing required parameter: device/',
    "check that new() croaks on missing 'device' parameter" );
is( $obj, undef, "check that the object is undef" );

# instanciate an object with the mock driver
$obj = eval { Device::TLSPrinter->new(type => "mock", device => "") };
# note: there's a pass() made by Device::TLSPrinter::Mock::init()
isa_ok( $obj, "Device::TLSPrinter::Mock", "check that object " );

