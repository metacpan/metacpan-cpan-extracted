#!perl -T

use Test::More;
use Device::USB;
use strict;
use warnings;
use constant TESTS_PER_DEVICE => 14;

my $usb = Device::USB->new();
if(defined $usb)
{
    my @devices = $usb->list_devices();
    plan tests => 2 + TESTS_PER_DEVICE * scalar @devices;
}
else
{
    fail( "Unable to create USB object." );
}

my $busses = $usb->list_busses();
ok( defined $busses, "USB busses found" );

can_ok( "Device::USB::Device",
        qw/filename configurations get_configuration
        bcdUSB bDeviceClass bDeviceSubClass
       bDeviceProtocol bMaxPacketSize0 idVendor idProduct
       bcdDevice iManufacturer iProduct iSerialNumber bNumConfigurations/ );

foreach my $bus (@{$busses})
{
    foreach my $dev (@{$bus->devices()})
    {
        isa_ok( $dev, "Device::USB::Device" );
        my $filename = $dev->filename();
        my $regex = ($^O !~ /win/i) ? qr/^(?:\d+|[0-9a-f-]+)$/ : qr/^[\\.]*[0-9a-z-]+$/;
        like( $filename, $regex, "Filename is a valid format" );
        my $configs = $dev->configurations();
        isa_ok( $configs, 'ARRAY' );
        like( $dev->bcdUSB(), qr/^\d+\.\d+$/, "$filename: USB Version" );
        like( $dev->bDeviceClass(), qr/^\d+$/, "$filename: device class" );
        like( $dev->bDeviceSubClass(), qr/^\d+$/, "$filename: device subclass" );
        like( $dev->bMaxPacketSize0(), qr/^\d+$/, "$filename: max packet size" );
        like( $dev->idVendor(), qr/^\d+$/, "$filename: vendor id" );
        like( $dev->idProduct(), qr/^\d+$/, "$filename: product id" );
        like( $dev->bcdDevice(), qr/^\d+\.\d+$/, "$filename: Device version" );
        like( $dev->iManufacturer(), qr/^\d+$/, "$filename: manufacturer index" );
        like( $dev->iProduct(), qr/^\d+$/, "$filename: product index" );
        like( $dev->iSerialNumber(), qr/^\d+$/, "$filename: serial number index" );
        is( $dev->bNumConfigurations(), scalar(@{$configs}),
            "$filename: number of configurations matches" );
    }
}

