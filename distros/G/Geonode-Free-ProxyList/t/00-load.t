#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

use_ok( 'Geonode::Free::ProxyList' )
    or bail_out( 'Cannot load module Geonode::Free::ProxyList' );

use_ok( 'Geonode::Free::Proxy' )
    or bail_out( 'Cannot load module Geonode::Free::Proxy' );
