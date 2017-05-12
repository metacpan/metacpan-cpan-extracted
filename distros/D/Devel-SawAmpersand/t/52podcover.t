# -*- mode: cperl -*-
use Test::More;
eval "use 5.00504";
plan skip_all => "perl 5.00504 required for this test" if $@;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
my $trustme = { trustme => [ qw{
                              }]
              };
pod_coverage_ok( "Devel::SawAmpersand", $trustme );
