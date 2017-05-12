#!perl -T

use strict;
use warnings;

use Test::More;
use Class::Load qw(try_load_class);

BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};
}

my $tp_version = "1.14";
try_load_class("Test::Pod", {-version => $tp_version})
    or plan skip_all =>
        "Test::Pod $tp_version required for testing POD";

Test::Pod::all_pod_files_ok();

# vim: expandtab shiftwidth=4
