#!perl

use strict;
use warnings;
use Test::More tests => 1;
use IO::File;
use Linux::Sysfs qw(:all);

ok( 1, 'Keep Test::More happy' );

my $fh = IO::File->new('t/config.pl', 'w')
    or BAIL_OUT("Could not open t/config.pl for writing.\n".
            "The test suite won't work without it. BAILING OUT");

$fh->print(<<'EOH');
#!perl

{
    inval_name => 'invalid_name',
    inval_path => '/sys/invalid/path',
EOH

$fh->print("    val_block_class_dev_path => '". find_disk_device() . "',\n");
$fh->print("    val_bus_id => '0000:00:00.0',\n"); #FIXME: autodetect
$fh->print("    val_bus_name => '". find_bus_name() ."',\n");
$fh->print("    val_class => '". find_class_name() ."',\n");
$fh->print("    val_class_dev => '". find_class_dev_name() ."',\n");
$fh->print("    val_class_dev_attr => '". find_class_dev_attr() ."',\n");
$fh->print("    val_class_dev_path => '". find_class_path() ."',\n");
$fh->print("    val_dev_path => '". find_dev_path() ."',\n");
$fh->print("    val_dev_attr => '". find_dev_attr() ."',\n");
$fh->print("    val_drv_name => '". find_drv_name() ."',\n");
$fh->print("    val_drv_attr_name => 'new_id',\n");
$fh->print("    val_drv_bus_name => '". find_bus_name() ."',\n");
$fh->print("    val_drv_path => '". find_drv_path() ."',\n");
$fh->print("    val_file_path => '". find_file_path() ."',\n");
$fh->print("    val_mod_name => '", find_mod_name() ."',\n");
$fh->print("    val_mod_attr_name => 'refcnt',\n");
$fh->print("    val_mod_section => '__versions',\n");
$fh->print("    val_mod_parm => '". find_mod_parm() ."',\n");
$fh->print("    val_mod_path => '". find_mod_path() ."',\n");
$fh->print("    val_write_attr_path => '". find_write_attr_path() ."',\n");

$fh->print(<<'EOF');
}
EOF

$fh->close;

sub find_disk_device {
    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$BLOCK_NAME";

    my $disk_device;
    for my $dev_path (find_device_paths($path, sub { -d $_ && $_[1] =~ /da$/ })) {
        if (my @children = sort { $a->[1] cmp $b->[1] } find_device_paths($dev_path->[0], sub { -d $_ && $_[1] =~ /da\d+/ })) {
            $disk_device = $children[0]->[0];
            last;
        }
    }

    return $disk_device;
}

sub find_bus_name {
    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$BUS_NAME";

    my @bus_names = sort prefered_bus_names
        map { $_->[1] }
        find_device_paths($path, sub { -d $_ });

    return $bus_names[0];
}

sub prefered_bus_names {
    return -1 if $a eq 'pci';
    return  1 if $b eq 'pci';
    return -1 if $a eq 'scsi';
    return  1 if $b eq 'scsi';
    return -1 if $a eq 'pci_express';
    return  1 if $b eq 'pci_express';

    return $a cmp $b;
}

sub find_class_name {
    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$CLASS_NAME";

    my @class_names = sort prefered_class_names
        map { $_->[1] }
        find_device_paths($path, sub {
                return unless -d $_;

                my @attrs = glob "$_/*/*";
                my $has_readable_attr;
                for my $attr (@attrs) {
                    next if $attr eq 'dev';
                    next if $attr eq 'uevent';

                    $has_readable_attr = 1
                        if -r $attr;
                }

                return $has_readable_attr;
        });

    return $class_names[0];
}

sub find_class_path {
    my $class = find_class_name();
    my $classdev = find_class_dev_name();

    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$CLASS_NAME";
    $path .= "/$class";
    $path .= "/$classdev";
}

sub prefered_class_names {
    return -1 if $a eq 'net';
    return  1 if $b eq 'net';
    return -1 if $a eq 'misc';
    return  1 if $b eq 'misc';
    return -1 if $a eq 'pci_bus';
    return  1 if $b eq 'pci_bus';

    return $a cmp $b;
}

sub find_class_dev_name {
    my $class = find_class_name();

    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$CLASS_NAME";
    $path .= "/$class";

    return (find_device_paths($path, sub { -d $_ }))[0]->[1];
}

sub find_class_dev_attr {
    my $class = find_class_name();
    my $classdev = find_class_dev_name();

    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$CLASS_NAME";
    $path .= "/$class";
    $path .= "/$classdev";

    return (find_device_paths($path, sub { -f $_ && -r $_ && $_ ne 'dev' && $_ ne 'uevent' }))[0]->[1];
}

sub find_dev_path {
    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$DEVICES_NAME";

    for my $bus (sort prefered_dev_bus_names find_device_paths($path, sub { -d $_ })) {
        my @devices = find_device_paths($bus->[0], sub {
                my @attrs = find_device_paths($_, sub { -f $_ && -r $_ && $_ ne 'dev' && $_ ne 'uevent' });
                return scalar @attrs;
        });

        next unless @devices;
        return $devices[0]->[0];
    }
}

sub prefered_dev_bus_names {
    return  1 if $b->[1] =~ /^pci/;
    return -1 if $a->[1] =~ /^pci/;
    return  1 if $b->[1] eq 'platform';
    return -1 if $a->[1] eq 'platform';

    return $a->[1] cmp $b->[1];
}

sub find_dev_attr {
    my $dev = find_dev_path();

    return (find_device_paths($dev, sub { -f $_ && -r $_ && $_ ne 'dev' && $_ ne 'uevent' && $_[1] !~ /^resource/ && $_[1] !~ /^rom/ }))[0]->[1];
}

sub find_drv {
    my $bus = find_bus_name();

    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$BUS_NAME";
    $path .= "/$bus";
    $path .= "/$DRIVERS_NAME";

    return (find_device_paths($path, sub { -d $_ }))[0];
}

sub find_drv_name {
    return find_drv()->[1];
}

sub find_drv_path {
    return find_drv()->[0];
}

sub find_file_path {
    return find_disk_device() .'/dev';
}

sub find_mod {
    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$MODULE_NAME";

    return (find_device_paths($path, sub { -d $_ && -d "$_/parameters" }))[0];
}

sub find_mod_name {
    return find_mod()->[1];
}

sub find_mod_path {
    return find_mod()->[0];
}

sub find_mod_parm {
    my $path = find_mod_path();
    $path .= '/parameters';

    return (find_device_paths($path, sub { -f $_ && -r $_ }))[0]->[1];
}

sub find_write_attr_path {
    my $path = Linux::Sysfs->get_mnt_path;
    $path .= "/$CLASS_NAME";
    $path .= "/".find_class_name();

    my $write_attr = 0;
    for my $dev (find_device_paths($path, sub { -d $_ })) {
        if (my @attrs = find_device_paths($dev->[0], sub { -f $_ && -w $_ })) {
            $write_attr = $attrs[0]->[0];
            last;
        }
    }

    return $write_attr;
}

sub find_device_paths {
    my ($path, $is_interesting) = @_;
    my @paths;

    return unless -d $path;
    opendir my $dir, $path
        or do {
            use Data::Dumper;
            diag(Dumper(caller()));
            BAIL_OUT("Could not open $path");
        };

    while (my $child = readdir $dir) {
        next if $child eq '.';
        next if $child eq '..';

        my $child_path = "${path}/${child}";
        local $_ = $child_path;

        if ($is_interesting->($child_path, $child)) {
            push @paths, [ $child_path, $child ]
        }
    }

    closedir $dir;
    return @paths;
}
