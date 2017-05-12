#!perl

use strict;
use warnings;
use Linux::Sysfs;

BEGIN {
    require 't/common.pl';
}

plan tests => 36;

# close
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    lives_ok(sub {
            $module->close;
    }, 'close');
}

{
    my $module = bless \(my $s), 'Linux::Sysfs::Module';

    lives_ok(sub {
            $module->close;
    }, 'close on invalid module');
}


# open_path
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    show_module($module);
    $module->close;
}

{
    my $module = Linux::Sysfs::Module->open_path($inval_path);
    ok( !defined $module, 'open_path with invalid path' );
}

{
    no warnings 'uninitialized';
    my $module = Linux::Sysfs::Module->open_path(undef);
    ok( !defined $module, 'open_path with undefined path' );
}


# open
{
    my $module = Linux::Sysfs::Module->open($val_mod_name);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    show_module($module);
    $module->close;
}

{
    my $module = Linux::Sysfs::Module->open($inval_name);
    ok( !defined $module, 'open with invalid name' );
}

TODO: {
    local $TODO = 'will fail in future';

    no warnings 'uninitialized';
    my $module = Linux::Sysfs::Module->open(undef);
    ok( !defined $module, 'open with undefined name' );
}


# get_attr
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    my $attr = $module->get_attr($val_mod_attr_name);
    isa_ok( $attr, 'Linux::Sysfs::Attribute' ); #TODO: errno

    show_attribute($attr);
    
    $attr = $module->get_attr($inval_name);
    ok( !defined $attr, 'get_attr with invalid name' );

    {
        no warnings 'uninitialized';
        $attr = $module->get_attr(undef);
        ok( !defined $attr, 'get_attr with undefined name' );
    }

    $module->close;
}


# get_attributes
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    my @attrs = $module->get_attributes;
    ok( scalar @attrs > 0, 'get_attributes' );

    show_attribute_list(\@attrs);
    $module->close;
}

{
    my $module = bless \(my $s), 'Linux::Sysfs::Module';

    my @attrs = $module->get_attributes;
    ok( scalar @attrs == 0, 'get_attributes on invalid module' );
}


# get_parms
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    my @parms = $module->get_parms;
    ok( scalar @parms > 0, 'get_parms' );

    show_parm_list(\@parms);
    $module->close;
}

{
    my $module = bless \(my $s), 'Linux::Sysfs::Module';

    my @parms = $module->get_parms;
    ok( scalar @parms == 0, 'get_parms on invalid module' );
}


# get_sections
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    my @sects = $module->get_sections;
    ok( scalar @sects > 0, 'get_sections' );

    show_section_list(\@sects);
    $module->close;
}

{
    my $module = bless \(my $s), 'Linux::Sysfs::Module';

    my @sects = $module->get_sections;
    ok( scalar @sects == 0, 'get_sections on invalid module' );
}


# get_parm
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    my $parm = $module->get_parm($val_mod_parm);
    isa_ok( $parm, 'Linux::Sysfs::Attribute' ); #TODO: errno

    show_attribute($parm);

    $parm = $module->get_parm($inval_name);
    ok( !defined $parm, 'get_parm with invalid name' );

    {
        no warnings 'uninitialized';
        $parm = $module->get_parm(undef);
        ok( !defined $parm, 'get_parm with undefined name' );
    }

    $module->close;
}

{
    my $module = bless \(my $s), 'Linux::Sysfs::Module';

    my $parm = $module->get_parm($val_mod_parm);
    ok( !defined $parm, 'get_parm on invalid module' );

    $parm = $module->get_parm($inval_name);
    ok( !defined $parm, 'get_parm on invalid module with invalid name' );

    {
        no warnings 'uninitialized';
        $parm = $module->get_parm(undef);
        ok( !defined $parm, 'get_parm on invalid module with undefined name' );
    }
}


# get_section
{
    my $module = Linux::Sysfs::Module->open_path($val_mod_path);
    isa_ok( $module, 'Linux::Sysfs::Module' );

    my $sect = $module->get_section($val_mod_section);
    isa_ok( $sect, 'Linux::Sysfs::Attribute' ); #TODO: errno

    show_attribute($sect);

    $sect = $module->get_section($inval_name);
    ok( !defined $sect, 'get_section with invalid name' );

    {
        no warnings 'uninitialized';
        $sect = $module->get_section(undef);
        ok( !defined $sect, 'get_section with undefined name' );
    }

    $module->close;
}

{
    my $module = bless \(my $s), 'Linux::Sysfs::Module';

    my $sect = $module->get_section($val_mod_section);
    ok( !defined $sect, 'get_section on invalid module' );

    $sect = $module->get_section($inval_name);
    ok( !defined $sect, 'get_section on invalid module with invalid name' );

    {
        no warnings 'uninitialized';
        $sect = $module->get_section(undef);
        ok( !defined $sect, 'get_section on invalid module with undefined name' );
    }
}
