#!perl

use strict;
use warnings;
use Linux::Sysfs;

BEGIN {
    require 't/common.pl';
}

plan tests => 16;

# close
{
    my $class = Linux::Sysfs::Class->open($val_class);
    isa_ok( $class, 'Linux::Sysfs::Class' );

    lives_ok(sub {
            $class->close;
    }, 'close');
}

{
    my $class = bless \(my $s), 'Linux::Sysfs::Class';

    lives_ok(sub {
            $class->close;
    }, 'close on invalid class');
}


# open
{
    my $class = Linux::Sysfs::Class->open($val_class);
    isa_ok( $class, 'Linux::Sysfs::Class' );

    debug(sprintf 'Class %s is at %s', $class->name, $class->path);
    $class->close;
}

{
    my $class = Linux::Sysfs::Class->open($inval_name);
    ok( !defined $class, 'open with invalid name' );
}

TODO: {
    local $TODO = 'Will fail in future';

    no warnings 'uninitialized';
    my $class = Linux::Sysfs::Class->open(undef);
    ok( !defined $class, 'open with undefined name' );
}


# get_devices
{
    my $class = Linux::Sysfs::Class->open($val_class);
    isa_ok( $class, 'Linux::Sysfs::Class' );

    my @devices = $class->get_devices;
    ok( scalar @devices > 0, 'get_devices' ); # TODO: errno

    show_device_list(\@devices);
    $class->close;
}

{
    my $class = bless \(my $s), 'Linux::Sysfs::Class';

    my @devices = $class->get_devices;
    ok( scalar @devices == 0, 'get_devices on invalid class' );
}


# get_device
{
    my $class = Linux::Sysfs::Class->open($val_class);
    isa_ok( $class, 'Linux::Sysfs::Class' );

    my $classdev = $class->get_device($val_class_dev);
    isa_ok( $classdev, 'Linux::Sysfs::ClassDevice' ); # TODO: errno
    show_class_device($classdev);

    $classdev = $class->get_device($inval_name);
    ok( !defined $classdev, 'get_device with invalid name' );

    TODO: {
        local $TODO = 'Will fail in future';

        no warnings 'uninitialized';
        $classdev = $class->get_device(undef);
        ok( !defined $classdev, 'get_device with undefined name' );
    }

    $class->close;
}

{
    my $class = bless \(my $s), 'Linux::Sysfs::Class';

    my $classdev = $class->get_device($val_class_dev);
    ok( !defined $classdev, 'get_device on invalid class' );

    $classdev = $class->get_device($inval_name);
    ok( !defined $classdev, 'get_device on invalid class with invalid name' );

    {
        no warnings 'uninitialized';
        $classdev = $class->get_device(undef);
        ok( !defined $classdev, 'get_device on invalid class with undefined name' );
    }
}
