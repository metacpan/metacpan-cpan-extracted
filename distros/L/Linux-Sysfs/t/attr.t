#!perl

use strict;
use warnings;
use Linux::Sysfs;

BEGIN {
    require 't/common.pl';
}

plan tests => 14;

# close 
{
    my $attr = Linux::Sysfs::Attribute->open($val_file_path);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' );

    lives_ok(sub {
            $attr->close;
    }, 'close');

}

{
    my $attr = bless \(my $s), 'Linux::Sysfs::Attribute';
    lives_ok(sub {
            $attr->close;
    }, 'close invalid pointer');
}


# open
{
    my $attr = Linux::Sysfs::Attribute->open($val_file_path);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' );

    debug(sprintf "Attrib name = %s, at %s", $attr->name, $attr->path);

    $attr->close;
}

{
    my $attr = Linux::Sysfs::Attribute->open($inval_path);
    ok( !defined $attr, 'open on invalid path' );
}

{
    no warnings 'uninitialized';
    my $attr = Linux::Sysfs::Attribute->open(undef);
    ok( !defined $attr, 'open on undefined value' );
}


# read
{
    my $attr = Linux::Sysfs::Attribute->open($val_file_path);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' );

    ok( $attr->read, 'read' );
    show_attribute($attr);

    $attr->close;
}

{
    my $attr = bless \(my $s), 'Linux::Sysfs::Attribute';
    ok( !$attr->read, 'read on invalid attr' );
}


# write
SKIP: {
    skip 'No write permissions to sysfs', 5 unless $val_write_attr_path;

    my $attr = Linux::Sysfs::Attribute->open($val_write_attr_path);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' );
    ok( $attr->read, 'read' );

    my $old_value = $attr->value;

    my $ret = $attr->write($old_value);
    ok( $ret, 'write' );

    debug(sprintf 'Attribute at %s now has value %s', $attr->path, $attr->value)
        if $ret;

    $ret = $attr->write('this should not get copied in the attrib');
    ok( !$ret, 'write invalid data' );

    $attr->close;


    my $fake_attr = bless \(my $s), 'Linux::Sysfs::Attribute';

    $ret = $fake_attr->write($old_value);
    ok( !$ret, 'write on invalid attr' );
}
