#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 6;
use Device::CableModem::Zoom5341J;

my $thisdir;
BEGIN { use File::Basename; $thisdir = dirname($0); }

my $cm = Device::CableModem::Zoom5341J->new;
isa_ok($cm, 'Device::CableModem::Zoom5341J', "Object built OK");


# Use sample data
use Device::CableModem::Zoom5341J::Test;
use File::Spec;
$cm->load_test_data(File::Spec->catfile($thisdir, 'sample.html'));

# Need to do this explicitly since this test reaches into the internals
$cm->parse_conn_stats;


# OK, spot-check make sure of what we've got
is($cm->{conn_stats}{down}{freq}[1], undef, "Got empty downfreq");
is($cm->{conn_stats}{down}{freq}[2], '175', "Got good downfreq");
is($cm->{conn_stats}{down}{snr}[1], undef, "Cleared downfreq");

is($cm->{conn_stats}{up}{chanid}[0], '1', "Got good upchan");
is($cm->{conn_stats}{up}{power}[0], '40.8', "Got good upchan power");

