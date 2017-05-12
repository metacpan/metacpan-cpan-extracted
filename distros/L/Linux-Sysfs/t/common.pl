#!perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );

eval "use Test::NoWarnings;";
my $HAS_TEST_NOWARNINGS = !(ref $@ || $@ ne '');

{
    no warnings 'redefine';
    sub plan {
        my ($cmd, $arg) = @_;

        if ($cmd eq 'tests' && $HAS_TEST_NOWARNINGS) {
            Test::More::plan(tests => $arg + 1);
        } else {
            Test::More::plan(@_);
        }
    }
}

eval "use Test::Exception ();";
my $HAS_TEST_EXCEPTION = !(ref $@ || $@ ne '');

sub lives_ok {
    if ($HAS_TEST_EXCEPTION) {
        Test::Exception::lives_ok(@_);
    } else {
        SKIP: {
            skip 'Needs Test::Exception', 1;
        }
    }
}

my $DEBUG = $ENV{TEST_DEBUG};

sub debug {
    my ($msg) = @_;
    diag($msg) if $DEBUG;
}

sub show_attribute {
    my ($attr) = @_;

    if (blessed $attr && $attr->isa('Linux::Sysfs::Attribute')) {
        if (my $value = $attr->value) {
            chomp $value;
            debug(sprintf 'Attr "%s" at "%s" has a value "%s"',
                    $attr->name, $attr->path, $value);
        }
    }
}

sub show_attribute_list {
    my ($attrs) = @_;

    for my $attr (@{ $attrs || [] }) {
        show_attribute($attr);
    }
}

sub show_device {
    my ($dev) = @_;

    if (blessed $dev && $dev->isa('Linux::Sysfs::Device')) {
        debug(sprintf 'Device is "%s" at "%s"', $dev->name, $dev->path);
    }
}

sub show_device_list {
    my ($devices) = @_;

    for my $dev (@{ $devices || [] }) {
        show_device($dev);
    }
}

sub show_driver {
    my ($drv) = @_;

    if (blessed $drv && $drv->isa('Linux::Sysfs::Driver')) {
        debug(sprintf 'Driver is "%s" at "%s"', $drv->name, $drv->path);
    }
}

sub show_driver_list {
    my ($drivers) = @_;

    for my $drv (@{ $drivers || [] }) {
        show_driver($drv);
    }
}

sub show_class_device {
    my ($classdev) = @_;

    if (blessed $classdev && $classdev->isa('Linux::Sysfs::ClassDevice')) {
        debug(sprintf 'Class device "%s" belongs to the "%s" class', $classdev->name, $classdev->classname);
    }
}

sub show_module {
    my ($module) = @_;

    if (blessed $module && $module->isa('Linux::Sysfs::Module')) {
        debug(sprintf 'Module name is %s, path is %s', $module->name, $module->path);
        show_attribute_list([$module->get_attributes]);
        show_parm_list([$module->get_parms]);
        show_section_list([$module->get_sections]);
    }
}

sub show_parm_list {
    my ($parms) = @_;

    for my $parm (@{ $parms || [] }) {
        debug($parm->name);
    }
}

sub show_section_list {
    my ($sections) = @_;

    for my $sect (@{ $sections || [] }) {
        debug($sect->name);
    }
}

package Where::The::Hell::Is::It::Documented::That::I::Can't::Export::Symbols::To::main::From::main::Questionmark;
# After trying to use the same piece of code without the above package statement
# I concluded it was a perl bug. I digged into the perl sources and found out
# that SVs (and other variables) are only marked as being imported (and therefor
# strict clean) if CopSTASH_ne(PL_curcop, GvSTASH(dest)), where dest is the SV
# to be copied to returns true. This is the case when the current control ops
# (PL_curcop) namespace doesn't match the namespace of the destination SV..
# See sv.c line 3776 (5.8.8).

my $conf = require 't/config.pl';

my $caller = (caller())[0];
while (my ($key, $val) = each(%{ $conf })) {
    no strict 'refs';
    *{ "${caller}::${key}" } = \$val;
}

1;
