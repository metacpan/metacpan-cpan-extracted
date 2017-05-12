#!perl

use strict;
use warnings;
use Linux::Sysfs;

BEGIN {
    require 't/common.pl';
}

plan tests => 29;

# close
{
    my $dev = Linux::Sysfs::ClassDevice->open_path($val_class_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::ClassDevice' );

    lives_ok(sub {
            $dev->close;
    }, 'close');
}

{
    my $dev = bless \(my $s), 'Linux::Sysfs::ClassDevice';

    lives_ok(sub {
            $dev->close;
    }, 'close on invalid class');
}


# open_path
{
    my $dev = Linux::Sysfs::ClassDevice->open_path($val_class_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::ClassDevice' );

    show_class_device($dev);
    $dev->close;
}

{
    my $dev = Linux::Sysfs::ClassDevice->open_path($inval_path);
    ok( !defined $dev, 'open_path on invalid path' );
}

{
    no warnings 'uninitialized';
    my $dev = Linux::Sysfs::ClassDevice->open_path(undef);
    ok( !defined $dev, 'open_path on undefined path' );
}


# open
{
    my $dev = Linux::Sysfs::ClassDevice->open($val_class, $val_class_dev);
    isa_ok( $dev, 'Linux::Sysfs::ClassDevice' );

    show_class_device($dev);

    $dev->close;
}

{
    my @opts = (
            [  $val_class,    $inval_name ],
# TODO      [  $val_class,          undef ],
            [ $inval_name, $val_class_dev ],
            [ $inval_name,    $inval_name ],
            [ $inval_name,          undef ],
            [       undef, $val_class_dev ],
            [       undef,    $inval_name ],
# TODO      [       undef,          undef ],
    );

    for my $opt (@opts) {
        my ($class, $name) = @{$opt};

        no warnings 'uninitialized';
        my $dev = Linux::Sysfs::ClassDevice->open($class, $name);
        ok( !defined $dev, 'open with invalid arguments' );
    }
}


# get_device
{
    my $classdev = Linux::Sysfs::ClassDevice->open($val_class, $val_class_dev);
    isa_ok( $classdev, 'Linux::Sysfs::ClassDevice' );

    my $dev = $classdev->get_device;
    isa_ok( $dev, 'Linux::Sysfs::Device' ); #TODO: errno

    show_device($dev);
    $classdev->close;
}

{
    my $classdev = bless \(my $s), 'Linux::Sysfs::ClassDevice';

    my $dev = $classdev->get_device;
    ok( !defined $dev, 'get_device on invalid class device' );
}


# get_parent
{
    my $classdev = Linux::Sysfs::ClassDevice->open_path($val_block_class_dev_path);
    isa_ok( $classdev, 'Linux::Sysfs::ClassDevice' );

    my $parent = $classdev->get_parent;
    isa_ok( $parent, 'Linux::Sysfs::ClassDevice' ); #TODO: errno

    show_class_device($parent);
    $classdev->close;
}

{
    my $classdev = bless \(my $s), 'Linux::Sysfs::ClassDevice';

    my $parent = $classdev->get_parent;
    ok( !defined $parent, 'get_parent on invalid class device' );
}


# get_attributes
{
    my $dev = Linux::Sysfs::ClassDevice->open_path($val_class_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::ClassDevice' );

    my @attrs = $dev->get_attributes;
    ok( scalar @attrs > 0, 'get_attributes' ); #TODO: errno

    show_attribute_list(\@attrs);
    $dev->close;
}

{
    my $dev = bless \(my $s), 'Linux::Sysfs::ClassDevice';

    my @attrs = $dev->get_attributes;
    ok( scalar @attrs == 0, 'get_attributes on invalid class device' );
}

# get_attr
{
    my $dev = Linux::Sysfs::ClassDevice->open_path($val_class_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::ClassDevice' );

    my $attr = $dev->get_attr($val_class_dev_attr);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' );

    $attr = $dev->get_attr($inval_name);
    ok( !defined $attr, 'get_attr with invalid name' );

    {
        no warnings 'uninitialized';
        $attr = $dev->get_attr(undef);
        ok( !defined $attr, 'get_attr with undefined name' );
    }

    $dev->close;
}

{
    my $dev = bless \(my $s), 'Linux::Sysfs::ClassDevice';

    my $attr = $dev->get_attr($val_class_dev_attr);
    ok( !defined $attr, 'get_attr on invalid class device' );

    $attr = $dev->get_attr($inval_name);
    ok( !defined $attr, 'get_attr on invalid class device with invalid name' );

    {
        no warnings 'uninitialized';
        $attr = $dev->get_attr(undef);
        ok( !defined $attr, 'get_attr on invalid class device with undefined name' );
    }
}
