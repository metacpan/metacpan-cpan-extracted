#!perl -T

use Test::More;
use Device::USB;
use strict;
use warnings;
use constant TESTS_PER_ENDPOINT => 7;

my $usb = Device::USB->new();
if(defined $usb)
{
    my $endpoint_count = 0;
    foreach my $dev ($usb->list_devices())
    {
        foreach my $config ($dev->configurations())
        {
            my @interfaces = map {@{$_}} $config->interfaces();
            $endpoint_count += $_->bNumEndpoints() foreach @interfaces;
        }
    }
    if($endpoint_count)
    {
        plan tests => 2 + TESTS_PER_ENDPOINT * $endpoint_count;
    }
    else
    {
        plan skip_all => 'No devices found.';
    }
}
else
{
    fail( "Unable to create USB object." );
}

my @devices = $usb->list_devices();
isnt( scalar @devices, 0, "USB devices found" );

can_ok( "Device::USB::DevEndpoint",
        qw/bEndpointAddress bmAttributes wMaxPacketSize bInterval
           bRefresh bSynchAddress/
);

foreach my $dev (@devices)
{
    my $filename = $dev->filename();
    my $cfgno = 0;
    foreach my $cfg ($dev->configurations())
    {
        foreach my $if (map { @{$_} } $cfg->interfaces())
        {
            my $ifno = $if->bInterfaceNumber();
            foreach my $ep ($if->endpoints())
            {
                my $descr = "$filename:$cfgno:$ifno:".$ep->bEndpointAddress();
                isa_ok( $ep, "Device::USB::DevEndpoint" );
                like( $ep->bEndpointAddress(), qr/^\d+$/, "$descr: Endpoint Address" );
                like( $ep->bmAttributes(), qr/^\d+$/, "$descr: Attributes" );
                like( $ep->wMaxPacketSize(), qr/^\d+$/, "$descr: Max Packet Size" );
                like( $ep->bInterval(), qr/^\d+$/, "$descr: Interval" );
                like( $ep->bRefresh(), qr/^\d+$/, "$descr: Refresh" );
                like( $ep->bSynchAddress(), qr/^\d+$/, "$descr: Synch Address" );
            }
        }
        ++$cfgno;
    }
}

