use strict;
use Test::More;

eval "use Test::Pod::Coverage;";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

plan tests => 4;

my $trm = { 'trustme' => [ 'NamesRgbTable' ] }; # for use by base module

pod_coverage_ok( 'Graphics::ColorNames::WWW', $trm );
pod_coverage_ok( 'Graphics::ColorNames::SVG', $trm );
pod_coverage_ok( 'Graphics::ColorNames::IE', $trm );
pod_coverage_ok( 'Graphics::ColorNames::CSS', $trm );
