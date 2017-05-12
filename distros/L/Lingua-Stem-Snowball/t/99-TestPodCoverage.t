#!/usr/bin/perl

use Test::More;
plan skip_all => "Test::Pod::Coverage required for testing POD"
    unless eval "use Test::Pod::Coverage; 1";
plan tests => 1;
my $trustme = { trustme => [qr/^dl_load_flags$/] };
pod_coverage_ok( "Lingua::Stem::Snowball", $trustme );
