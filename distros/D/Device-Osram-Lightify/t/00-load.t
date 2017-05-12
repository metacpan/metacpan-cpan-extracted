#!/usr/bin/perl -Iblib/lib/

use strict;
use warnings;

use Test::More tests => 6;

BEGIN
{
    use_ok( "Device::Osram::Lightify::API",   "We could load the module" );
    use_ok( "Device::Osram::Lightify::Hub",   "We could load the module" );
    use_ok( "Device::Osram::Lightify::Light", "We could load the module" );
    use_ok( "Device::Osram::Lightify",        "We could load the module" );
}

ok( $Device::Osram::Lightify::VERSION, "Version defined" );
ok( $Device::Osram::Lightify::VERSION =~ /^([0-9\.]+)/, "Version is numeric" );
