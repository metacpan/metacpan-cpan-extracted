#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan $@
    ? (
    skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" )
    : ( tests => 2 );

pod_coverage_ok( 'Kwiki::Users::Remote', { trustme => [] } );
pod_coverage_ok( 'Kwiki::UserName::Remote',
    { trustme => [qr{\A (register) \Z}x] } );
