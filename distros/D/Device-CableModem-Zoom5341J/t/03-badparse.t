#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 5;
use Device::CableModem::Zoom5341J;

my $cm = Device::CableModem::Zoom5341J->new;
isa_ok($cm, 'Device::CableModem::Zoom5341J', "Object built OK");

# Turn off fetching for our purposes here
$cm->{__TESTING_NO_FETCH} = 1;

# First, try it with NO data
$cm->{conn_html} = undef; # Just to be sure
eval { $cm->parse_conn_stats };
like($@, qr/No HTML/,
     "->parse_conn_stats fails properly with no data");
is($cm->{conn_stats}, undef, "No HTML leads to no parsed data");

# Now try with horribly bad data
$cm->{conn_html} = "Hahaha, yeah right!\nNFW";
eval { $cm->parse_conn_stats };
like($@, qr/Couldn't find/,
     "->parse_conn_stats fails properly with bad data");
is($cm->{conn_stats}, undef, "Bad HTML leads to bad parsed data");
