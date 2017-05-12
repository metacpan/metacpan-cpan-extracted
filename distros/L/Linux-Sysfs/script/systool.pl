#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use Linux::Sysfs qw(:all);

use constant {
    SHOW_ATTRIBUTES         => 0x01,
    SHOW_ATTRIBUTE_VALUE    => 0x02,
    SHOW_DEVICES            => 0x04,
    SHOW_DRIVERS            => 0x08,
    SHOW_ALL_ATTRIB_VALUES  => 0x10,
    SHOW_CHILDREN           => 0x20,
    SHOW_PARENT             => 0x40,
    SHOW_PATH               => 0x80,
    SHOW_ALL                => 0xff,
};

my %opts;
getopts('aA:b:c:dDhm:pPv', \%opts);

my ($show_options, $device_to_show, $attribute_to_show, $show_bus, $show_class, $show_module, $show_root, $retval);
$show_options = 0;

while (my ($opt, $val) = each %opts) {
    if ($opt eq 'a') {
        $show_options |= SHOW_ATTRIBUTES;
    }
    elsif ($opt eq 'A') {
        $attribute_to_show = $val;
        $show_options |= SHOW_ATTRIBUTE_VALUE;
    }
    elsif ($opt eq 'b') {
        $show_bus = $val;
    }
    elsif ($opt eq 'c') {
        $show_class = $val;
    }
    elsif ($opt eq 'd') {
        $show_options |= SHOW_DEVICES;
    }
    elsif ($opt eq 'D') {
        $show_options |= SHOW_DRIVERS;
    }
    elsif ($opt eq 'h') {
        usage();
        exit 0;
    }
    elsif ($opt eq 'm') {
        $show_module = $val;
    }
    elsif ($opt eq 'p') {
        $show_options |= SHOW_PATH;
    }
    elsif ($opt eq 'P') {
        $show_options |= SHOW_PARENT;
    }
    elsif ($opt eq 'v') {
        $show_options |= SHOW_ALL_ATTRIB_VALUES;
    }
    else {
        usage();
        exit 1;
    }
}

if (@ARGV == 1) {
    $device_to_show = $ARGV[0];
    $show_options |= SHOW_DEVICES;
}
elsif (@ARGV != 0) {
    usage();
    exit 1;
}

unless (check_sysfs_is_mounted()) {
    print "Unable to find sysfs mount point!\n";
    exit 1;
}


if (!$show_bus && !$show_class && !$show_module && !$show_root
        && ($show_options & (SHOW_ATTRIBUTES
                | SHOW_ATTRIBUTE_VALUE | SHOW_DEVICES 
                | SHOW_DRIVERS | SHOW_ALL_ATTRIB_VALUES))) {
    print "Please specify a bus, class, module, or root device\n";
    usage();
    exit 1;
}


if (!( $show_options & (SHOW_DEVICES | SHOW_DRIVERS) )) {
    $show_options |= SHOW_DEVICES;
}

if ($show_bus) {
    if ($show_bus eq 'pci') {
        #TODO: pci_ids
    }
    $retval = show_sysfs_bus($show_bus);
}

if ($show_class) {
    $retval = show_sysfs_class($show_class);
}

if ($show_module) {
    $retval = show_sysfs_module($show_module);
}

if (!$show_bus && !$show_class && !$show_module && !$show_root) {
    $retval = show_default_info();
}

if ($show_bus && $show_bus eq 'pci') {
    #TODO: pci ids
}

if (!( $show_options ^ SHOW_DEVICES )) {
    print "\n";
}

exit($retval);

sub usage {
    print <<"EOU";
Usage: $0 [<options> [device]]
\t-a\t\t\tShow attributes
\t-b <bus_name>\t\tShow a specific bus
\t-c <class_name>\t\tShow a specific class
\t-d\t\t\tShow only devices
\t-h\t\t\tShow usage
\t-m <module_name>\tShow a specific module
\t-p\t\t\tShow path to device/driver
\t-v\t\t\tShow all attributes with values
\t-A <attribute_name>\tShow attribute value
\t-D\t\t\tShow only drivers
\t-P\t\t\tShow device's parent
EOU
}

sub indent {
    my ($level) = @_;

    print " " x $level;
}

sub is_binary_value {
    my ($attr) = @_;

    return unless $attr;

    return 1 if $attr->name eq 'config';
    return 1 if $attr->name eq 'data';

    return;
}

sub show_attribute {
    my ($attr, $level) = @_;
    return unless $attr;

    if ($show_options & SHOW_ALL_ATTRIB_VALUES) {
        indent($level);
        printf "%-20s= ", $attr->name;
        show_attribute_value($attr, $level);
    }
    elsif ( ($show_options & SHOW_ATTRIBUTES)
         || ($show_options & SHOW_ATTRIBUTE_VALUE)
         && ($attribute_to_show && $attr->name eq $attribute_to_show) ) {
        indent($level);
        printf "%-20s", $attr->name;

        if ( ($show_options & SHOW_ATTRIBUTE_VALUE) && defined $attr->value
                && ($attribute_to_show && $attr->name eq $attribute_to_show) ) {
            print "= ";
            show_attribute_value($attr, $level);
        }
        else {
            print "\n";
        }
    }
}

sub show_attribute_value {
    my ($attr, $level) = @_;
    return unless $attr;

    if ($attr->can_read) {
        if (is_binary_value($attr)) {
            for (my $i = 0; $i < length $attr->value; $i++) {
                if (!($i % 16) && ($i != 0)) {
                    print "\n";
                    indent($level+22);
                }
                elsif (!($i % 8) && ($i != 0)) {
                    print " ";
                }
                printf '%02x', pack("C*", substr($attr->value, $i));
            }
        }
        elsif (defined $attr->value && length $attr->value > 0) {
            my $value = $attr->value;
            chomp $value;
            print "\"$value\"\n";
        }
        else {
            print "\n";
        }
    }
    else {
        print "<store method only>\n";
    }
}

sub check_sysfs_is_mounted {
    return defined Linux::Sysfs->get_mnt_path;
}

sub show_sysfs_bus {
    my ($busname) = @_;

    my $bus = Linux::Sysfs::Bus->open($busname);
    if (!$bus) {
        print "Error opening bus $busname\n";
        exit 1;
    }

    print "Bus = \"$busname\"\n";

    if ($show_options ^ (SHOW_DEVICES | SHOW_DRIVERS)) {
        print "\n";
    }

    if ($show_options & SHOW_DEVICES) {
        for my $dev ($bus->get_devices) {
            if (!$device_to_show || $device_to_show eq $dev->bus_id) {
                show_device($dev, 2);
            }
        }
    }

    if ($show_options & SHOW_DRIVERS) {
        for my $drv ($bus->get_drivers) {
            show_driver($drv, 2);
        }
    }
}

sub show_sysfs_class {
    my ($classname) = @_;

    my $cls = Linux::Sysfs::Class->open($classname);
    if (!$cls) {
        print "Error opening class $classname\n";
        exit 1;
    }

    print "Class = \"$classname\"\n\n";

    for my $clsdev ($cls->get_devices) {
        if (!$device_to_show || $clsdev->name eq $device_to_show) {
            show_class_device($clsdev, 2);
        }
    }

    $cls->close;
    return 0;
}

sub show_class_device {
    my ($dev, $level) = @_;
    return unless $dev;

    indent($level);
    printf "Class Device = \"%s\"\n", $dev->name;

    if ($show_options & (SHOW_PATH | SHOW_ALL_ATTRIB_VALUES)) {
        indent($level);
        printf "Class Device path = \"%s\"\n", $dev->path;
    }

    if ($show_options & (SHOW_ATTRIBUTES | SHOW_ATTRIBUTE_VALUE | SHOW_ALL_ATTRIB_VALUES)) {
        for my $attr ($dev->get_attributes) {
            show_attribute($attr, $level + 2);
        }
        print "\n";
    }

    if ($show_options & (SHOW_DEVICES | SHOW_ALL_ATTRIB_VALUES)) {
        my $device = $dev->get_device;
        show_device($device, $level + 2) if $device;
    }

    if ($device_to_show && ($show_options & SHOW_PARENT)) {
        $show_options &= ~SHOW_PARENT;
        show_classdev_parent($dev, $level + 2);
    }

    if ($show_options & ~(SHOW_ATTRIBUTES | SHOW_ATTRIBUTE_VALUE | SHOW_ALL_ATTRIB_VALUES)) {
        print "\n";
    }
}

sub show_device {
    my ($device, $level) = @_;
    return unless $device;

    indent($level);

    if ($show_bus && $show_bus eq 'pci') {
        #TODO: pci ids
    }
    else {
        printf "Device = \"%s\"\n", $device->bus_id;
    }

    if ($show_options & (SHOW_PATH | SHOW_ALL_ATTRIB_VALUES)) {
        indent($level);
        printf "Device path = \"%s\"\n", $device->path;
    }

    if ($show_options & (SHOW_ATTRIBUTES | SHOW_ATTRIBUTE_VALUE | SHOW_ALL_ATTRIB_VALUES)) {
        for my $attr ($device->get_attributes) {
            show_attribute($attr, $level + 2);
        }
    }

    if ($device_to_show && ($show_options & SHOW_PARENT)) {
        $show_options &= ~SHOW_PARENT;
        show_device_parent($device, $level + 2);
    }

    if ($show_options ^ SHOW_DEVICES) {
        if (!($show_options & SHOW_DRIVERS)) {
            print "\n";
        }
    }
}

sub show_device_parent {
    my ($device, $level) = @_;

    my $parent = $device->get_parent;
    return unless $parent;

    print "\n";
    indent($level);
    printf "Device \"%s\"'s parent\n", $device->name;
    show_device($parent, $level + 2);
}

sub show_classdev_parent {
    my ($dev, $level) = @_;

    my $parent = $dev->get_parent;
    return unless $parent;

    print "\n";
    indent($level);
    printf "Class device \"%s\"'s parent is\n", $dev->name;

    show_class_device($parent, $level + 2);
}

sub show_sysfs_module {
    my ($module) = @_;

    my $mod = Linux::Sysfs::Module->open($module);
    if (!$mod) {
        print "Error opening module $module\n";
        exit 1;
    }

    print "Module = \"$module\"\n\n";

    if ($show_options & (SHOW_ATTRIBUTES | SHOW_ATTRIBUTE_VALUE | SHOW_ALL_ATTRIB_VALUES)) {
        if ($show_options & (SHOW_ATTRIBUTES | SHOW_ALL_ATTRIB_VALUES)) {
            if (my @attributes = $mod->get_attributes) {
                indent(2);
                print "Attributes:\n";

                for my $attr (@attributes) {
                    show_attribute($attr, 4);
                }
            }

            if (my @attributes = $mod->get_parms) {
                print "\n";
                indent(2);
                print "Parameters:\n";

                for my $attr (@attributes) {
                    show_attribute($attr, 4);
                }
            }

            if (my @attributes = $mod->get_sections) {
                print "\n";
                indent(2);
                print "Sections:\n";

                for my $attr (@attributes) {
                    show_attribute($attr, 4);
                }
            }
        }
    }

    $mod->close;
    return 0;
}

sub show_default_info {
    my $path = Linux::Sysfs->get_mnt_path;

    print "Supported sysfs buses:\n";
    print_dir_list("${path}/${BUS_NAME}");

    print "Supported sysfs classes:\n";
    print_dir_list("${path}/${CLASS_NAME}");

    print "Supported sysfs devices:\n";
    print_dir_list("${path}/${DEVICES_NAME}");

    print "Supported sysfs modules:\n";
    print_dir_list("${path}/${MODULE_NAME}");

    return 0;
}

sub print_dir_list {
    my ($path) = @_;

    opendir(my $dir_handle, $path) or die $!;
    my @files = readdir($dir_handle);
    closedir($dir_handle);

    for my $dir (sort @files) {
        next if $dir eq '.';
        next if $dir eq '..';
        next unless -d "${path}/${dir}";

        print "\t$dir\n";
    }
}
