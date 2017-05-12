#!perl

use strict;
use warnings;
use Linux::Sysfs;

BEGIN {
    require 't/common.pl';
}

plan tests => 27;

# close
{
    my $driver = Linux::Sysfs::Driver->open_path($val_drv_path);
    isa_ok( $driver, 'Linux::Sysfs::Driver' );

    lives_ok(sub {
            $driver->close;
    }, 'close');
}

{
    my $driver = bless \(my $s), 'Linux::Sysfs::Driver';

    lives_ok(sub {
            $driver->close;
    }, 'close');
}


# open_path
{
    my $driver = Linux::Sysfs::Driver->open_path($val_drv_path);
    isa_ok( $driver, 'Linux::Sysfs::Driver' );

    show_driver($driver);
    $driver->close;
}

{
    my $driver = Linux::Sysfs::Driver->open_path($inval_path);
    ok( !defined $driver, 'open_path with invalid path' );
}

{
    no warnings 'uninitialized';
    my $driver = Linux::Sysfs::Driver->open_path(undef);
    ok( !defined $driver, 'open_path with undefined path' );
}


# open
{
    my @opts = (
            [ $val_drv_bus_name, $val_drv_name, 1 ],
            [ $val_drv_bus_name,   $inval_name, 0 ],
#TODO       [ $val_drv_bus_name,         undef, 0 ],
            [       $inval_name, $val_drv_name, 0 ],
            [       $inval_name,   $inval_name, 0 ],
            [       $inval_name,         undef, 0 ],
            [             undef, $val_drv_name, 0 ],
            [             undef,   $inval_name, 0 ],
            [             undef,         undef, 0 ],
    );

    for my $opt (@opts) {
        my ($bus_name, $drv_name, $ret) = @{$opt};

        no warnings 'uninitialized';
        my $driver = Linux::Sysfs::Driver->open($bus_name, $drv_name);

        if ($ret) {
            isa_ok( $driver, 'Linux::Sysfs::Driver' );
            show_driver($driver);
            $driver->close;
        } else {
            ok( !defined $driver, 'open with invalid arguments' );
        }
    }
}


# get_attr
{
    my $driver = Linux::Sysfs::Driver->open_path($val_drv_path);
    isa_ok( $driver, 'Linux::Sysfs::Driver' );

    my $attr = $driver->get_attr($val_drv_attr_name);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' );

    show_attribute($attr);

    $attr = $driver->get_attr($inval_name);
    ok( !defined $attr, 'get_attr with invalid name' );

    {
        no warnings 'uninitialized';
        $attr = $driver->get_attr(undef);
        ok( !defined $attr, 'get_attr with undefined name' );
    }

    $driver->close;
}

{
    my $driver = bless \(my $s), 'Linux::Sysfs::Driver';

    my $attr = $driver->get_attr($val_drv_attr_name);
    ok( !defined $attr, 'get_attr on invalid driver' );

    $attr = $driver->get_attr($inval_name);
    ok( !defined $attr, 'get_attr on invalid driver with invalid name' );

    {
        no warnings 'uninitialized';
        $attr = $driver->get_attr(undef);
        ok( !defined $attr, 'get_attr on invalid driver with undefined name' );
    }
}


# get_attributes
{
    my $driver = Linux::Sysfs::Driver->open_path($val_drv_path);
    isa_ok( $driver, 'Linux::Sysfs::Driver' );

    my @attrs = $driver->get_attributes;
    ok( scalar @attrs > 0, 'get_attributes' ); #TODO: errno

    show_attribute_list(\@attrs);
    $driver->close;
}

{
    my $driver = bless \(my $s), 'Linux::Sysfs::Driver';

    my @attrs = $driver->get_attributes;
    ok( scalar @attrs == 0, 'get_attributes on invalid driver' );
}


# get_devices
{
    my $driver = Linux::Sysfs::Driver->open_path($val_drv_path);
    isa_ok( $driver, 'Linux::Sysfs::Driver' );

    my @devices = $driver->get_devices;
    ok( scalar @devices > 0, 'get_devices' ); #TODO: errno

    show_device_list(\@devices);
    $driver->close;
}

{
    my $driver = bless \(my $s), 'Linux::Sysfs::Driver';

    my @devices = $driver->get_devices;
    ok( scalar @devices == 0, 'get_devices on invalid driver' );
}
