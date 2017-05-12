#!/usr/bin/perl

use Test::More;
if ( eval "use Test::Pod::Coverage; 1" ) {
    plan( tests => 1 );
    pod_coverage_ok( "Lingua::StopWords",
        "Pod coverage is OK for Lingua::StopWords" );
}
else {
    plan( skip_all => "Test::Pod::Coverage required for testing POD" );
}

