#!perl -T

use strict;
use warnings;

use Test::More;
use Class::Load qw(try_load_class);

BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};
}

my $tpc_version = "1.04";
try_load_class("Test::Pod::Coverage", {-version => $tpc_version})
    or plan skip_all =>
        "Test::Pod::Coverage $tpc_version required for testing POD coverage";

Test::Pod::Coverage::all_pod_coverage_ok(
    { private => [ qr{^[A-Z]+$}, qr{^_}, qr{^import$} ] } );

# vim: expandtab shiftwidth=4
