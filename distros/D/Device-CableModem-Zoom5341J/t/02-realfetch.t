#!usr/bin/env perl5
use strict;
use warnings;

use Test::More;
use Device::CableModem::Zoom5341J;

unless($ENV{ZOOM_DO_NETTESTS})
{
	plan skip_all => 'Not doing network tests',
}

plan tests => 2;

my %oparms;
$oparms{modem_addr} = $ENV{ZOOM_ADDR} if $ENV{ZOOM_ADDR};

my $cm = Device::CableModem::Zoom5341J->new(%oparms);
isa_ok($cm, 'Device::CableModem::Zoom5341J', "Object built OK");

# Fetch the page
$cm->fetch_data;
ok($cm->{conn_html}, "Got HTML");
