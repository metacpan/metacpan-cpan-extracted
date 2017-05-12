#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 6;
use Device::CableModem::Zoom5341;

my $cm = Device::CableModem::Zoom5341->new;
isa_ok($cm, 'Device::CableModem::Zoom5341', "Object built OK");


# Use sample data
use Device::CableModem::Zoom5341::Test;
$cm->load_test_data;

# Need to do this explicitly since this test reaches into the internals
$cm->parse_conn_stats;


# OK, spot-check make sure of what we've got
is($cm->{conn_stats}{down}{freq}[1], '567.0000', "Got good downfreq");
is($cm->{conn_stats}{down}{freq}[2], undef, "Got empty downfreq");
is($cm->{conn_stats}{down}{snr}[2], undef, "Cleared downfreq");

is($cm->{conn_stats}{up}{chanid}[0], '2', "Got good upchan");
is($cm->{conn_stats}{up}{power}[0], '41.7500', "Got good upchan power");

