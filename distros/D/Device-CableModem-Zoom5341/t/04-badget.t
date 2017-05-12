#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 7;
use Device::CableModem::Zoom5341;

my $cm = Device::CableModem::Zoom5341->new;
isa_ok($cm, 'Device::CableModem::Zoom5341', "Object built OK");


# Fake out the conn stats
$cm->{conn_stats} = {};


# Check that we properly error on down/up gets
eval { $cm->get_down_stats };
like($@, qr/No downstats/, "->get_down_stats errors on missing data");

eval { $cm->get_up_stats };
like($@, qr/No upstats/, "->get_down_stats errors on missing data");


# Now test individual down's
$cm->{conn_stats}{down} = { freq => ['abc'] };
eval { $cm->get_down_freq };
ok(!$@, "->get_down_freq didn't error");
eval { $cm->get_down_mod };
like($@, qr/No down modstats/, "->get_down_mod errored properly");

# And ups
$cm->{conn_stats}{up} = { chanid => ['abc'] };
eval { $cm->get_up_chanid };
ok(!$@, "->get_up_chanid didn't error");
eval { $cm->get_up_freq };
like($@, qr/No up freqstats/, "->get_up_freq errored properly");
