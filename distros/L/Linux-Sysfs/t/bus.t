#!perl

use strict;
use warnings;
use Linux::Sysfs;

BEGIN {
    require 't/common.pl';
}

plan tests => 25;

# close
{
    my $bus = Linux::Sysfs::Bus->open($val_bus_name);
    isa_ok( $bus, 'Linux::Sysfs::Bus' );

    lives_ok(sub {
            $bus->close;
    }, 'close');
}

{
    my $bus = bless \(my $s), 'Linux::Sysfs::Bus';

    lives_ok(sub {
            $bus->close;
    }, 'close on invalid bus');
}


# open
{
    my $bus = Linux::Sysfs::Bus->open($val_bus_name);
    isa_ok( $bus, 'Linux::Sysfs::Bus' );

    debug(sprintf 'Bus = %s, path = %s', $bus->name, $bus->path);

    $bus->close;
}

{
    my $bus = Linux::Sysfs::Bus->open($inval_name);
    ok( !defined $bus, 'open with invalid name' );
}


# get_device
{
    my $bus = Linux::Sysfs::Bus->open($val_bus_name);
    isa_ok( $bus, 'Linux::Sysfs::Bus' );

    my $dev = $bus->get_device($val_bus_id);
    isa_ok( $dev, 'Linux::Sysfs::Device' ); #TODO: errno?
    show_device($dev);

    $dev = $bus->get_device($inval_name);
    ok( !defined $dev, 'get_device with invalid id' );

    {
        no warnings 'uninitialized';
        $dev = $bus->get_device(undef);
        ok( !defined $dev, 'get_device with undefined id' );
    }

    $bus->close;
}

{
    my $bus = bless \(my $s), 'Linux::Sysfs::Bus';

    my $dev = $bus->get_device($val_bus_name);
    ok( !defined $dev, 'get_device on invalid bus' );

    $dev = $bus->get_device($inval_name);
    ok( !defined $dev, 'get_device on invalid bus with invalid id' );

    {
        no warnings 'uninitialized';
        $dev = $bus->get_device(undef);
        ok( !defined $dev, 'get_device on invalid bus with undefined id' ); 
    }
}


# get_driver
{
    my $bus = Linux::Sysfs::Bus->open($val_bus_name);
    isa_ok( $bus, 'Linux::Sysfs::Bus' );

    my $drv = $bus->get_driver($val_drv_name);
    isa_ok( $drv, 'Linux::Sysfs::Driver' ); #TODO: errno?

    $drv = $bus->get_driver($inval_name);
    ok( !defined $drv, 'get_driver with invalid name' );

    TODO: {
        local $TODO = 'will fail in future';

        no warnings 'uninitialized';
        $drv = $bus->get_driver(undef);
        ok( !defined $drv, 'get_driver with undefined name' );
    }
}

{
    my $bus = bless \(my $s), 'Linux::Sysfs::Bus';

    my $drv = $bus->get_driver($val_drv_name);
    ok( !defined $drv, 'get_driver on invalid bus' );

    $drv = $bus->get_driver($inval_name);
    ok( !defined $drv, 'get_driver on invalid bus with invalid name' );

    {
        no warnings 'uninitialized';
        $drv = $bus->get_driver(undef);
        ok( !defined $drv, 'get_driver on invalid bus with undefined name' );
    }
}


# get_drivers
{
    my $bus = Linux::Sysfs::Bus->open($val_bus_name);
    isa_ok( $bus, 'Linux::Sysfs::Bus' );

    my @drivers = $bus->get_drivers;
    ok( scalar @drivers > 0, 'get_drivers' ); #TODO: errno

    show_driver_list(\@drivers);

    $bus->close;
}

{
    my $bus = bless \(my $s), 'Linux::Sysfs::Bus';

    my @drivers = $bus->get_drivers;
    ok( scalar @drivers == 0, 'get_drivers on invalid bus' );
}


# get_devices
{
    my $bus = Linux::Sysfs::Bus->open($val_bus_name);
    isa_ok( $bus, 'Linux::Sysfs::Bus' );

    my @devices = $bus->get_devices;
    ok( scalar @devices > 0, 'get_devices' ); #TODO: errno

    show_device_list(\@devices);

    $bus->close;
}

{
    my $bus = bless \(my $s), 'Linux::Sysfs::Bus';

    my @devices = $bus->get_devices;
    ok( scalar @devices == 0, 'get_devices on invalid bus' );
}
