#!perl

use strict;
use warnings;
use Linux::Sysfs;

BEGIN {
    require 't/common.pl';
}

plan tests => 28;

# close
{
    my $dev = Linux::Sysfs::Device->open_path($val_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::Device' );

    lives_ok(sub {
            $dev->close;
    }, 'close');
}

{
    my $dev = bless \(my $s), 'Linux::Sysfs::Device';

    lives_ok(sub {
            $dev->close;
    }, 'close on invalid device');
}


# open
{
    my @opts = (
            [ $val_bus_name, $val_bus_id, 1 ],
            [ $val_bus_name, $inval_name, 0 ],
            [ $val_bus_name,       undef, 0 ],
            [   $inval_name, $val_bus_id, 0 ],
            [   $inval_name, $inval_name, 0 ],
            [   $inval_name,       undef, 0 ],
            [         undef, $val_bus_id, 0 ],
            [         undef, $inval_name, 0 ],
            [         undef,       undef, 0 ],
    );

    for my $opt (@opts) {
        my ($bus, $bus_id, $res) = @{$opt};

        no warnings 'uninitialized';
        my $dev = Linux::Sysfs::Device->open($bus, $bus_id);

        if ($res) {
            isa_ok( $dev, 'Linux::Sysfs::Device' );
        }
        else {
            ok( !defined $dev, 'open with invalid arguments' );
        }
    }
}


# get_parent
{
    my $dev = Linux::Sysfs::Device->open_path($val_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::Device' );

    my $parent = $dev->get_parent;
    isa_ok( $parent, 'Linux::Sysfs::Device' ); #TODO: errno

    show_device($parent);
    $dev->close;
}

{
    my $dev = bless \(my $s), 'Linux::Sysfs::Device';

    my $parent = $dev->get_parent;
    ok( !defined $parent, 'get_parent on invalid device' );
}


# open_path
{
    my $dev = Linux::Sysfs::Device->open_path($val_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::Device' );

    show_device($dev);
    $dev->close;
}

{
    my $dev = Linux::Sysfs::Device->open_path($inval_path);
    ok( !defined $dev, 'open_path with invalid path' );
}

{
    no warnings 'uninitialized';
    my $dev = Linux::Sysfs::Device->open_path(undef);
    ok( !defined $dev, 'open_path with undefined path' );
}


# get_attr
{
    my $dev = Linux::Sysfs::Device->open_path($val_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::Device' );

    use Data::Dumper;
#    diag(Dumper($dev->get_attr('config')));
    my $attr = $dev->get_attr($val_dev_attr);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' ); #TODO: errno

    show_attribute($attr);

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
    my $dev = bless \(my $s), 'Linux::Sysfs::Device';

    my $attr = $dev->get_attr($val_dev_attr);
    ok( !defined $attr, 'get_attr on invalid device' );

    $attr = $dev->get_attr($inval_name);
    ok( !defined $attr, 'get_attr on invalid device with invalid name' );

    {
        no warnings 'uninitialized';
        $attr = $dev->get_attr(undef);
        ok( !defined $attr, 'get_attr on invalid device with undefined name' );
    }
}


# get_attributes
{
    my $dev = Linux::Sysfs::Device->open_path($val_dev_path);
    isa_ok( $dev, 'Linux::Sysfs::Device' );

    my @attrs = $dev->get_attributes;
    ok( scalar @attrs > 0, 'get_attributes' ); #TODO: errno

    show_attribute_list(\@attrs);
    $dev->close;
}

{
    my $dev = bless \(my $s), 'Linux::Sysfs::Device';

    my @attrs = $dev->get_attributes;
    ok( scalar @attrs == 0, 'get_attributes on invalid device' );
}
