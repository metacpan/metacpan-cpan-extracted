#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 5;
use Device::CableModem::Zoom5341;

my $cm = Device::CableModem::Zoom5341->new;
isa_ok($cm, 'Device::CableModem::Zoom5341', "Object built OK");

# Turn off fetching for our purposes here
$cm->{__TESTING_NO_FETCH} = 1;

# First, try it with NO data
$cm->{conn_html} = undef; # Just to be sure
eval { $cm->parse_conn_stats };
like($@, qr/No HTML/,
     "->parse_connrow_vals fails properly with no data");
is($cm->{conn_stats}, undef, "No raw data leads to no parsed data");

# Now try with horribly bad data
$cm->{conn_html} = ['Hahaha, yeah right!', 'NFW'];
eval { $cm->parse_conn_stats };
like($@, qr/Bad row results/,
     "->parse_connrow_vals fails properly with bad data");
is($cm->{conn_stats}, undef, "Bad raw data leads to bad parsed data");
