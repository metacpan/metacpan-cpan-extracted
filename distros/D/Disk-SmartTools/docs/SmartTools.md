# NAME

Disk::SmartTools - Provide tools to work with disks via S.M.A.R.T.

# VERSION

Version v3.3.8

# SYNOPSIS

Provides disk related functions.

    use Disk::SmartTools;

    my $cmd_path = get_smart_cmd();


    ...

# EXPORT

    get_disk_prefix
    os_disks
    get_smart_cmd
    get_raid_cmd
    get_raid_flag
    get_diskutil_cmd
    get_physical_disks
    get_smart_disks
    is_drive_smart
    get_softraidtool_cmd

# SUBROUTINES/METHODS

## **get\_disk\_prefix()**

Returns the proper disk prefix depending on the OS: `/dev/sd` for linux, `/dev/disk` for macOS.

    my $disk_prefix = get_disk_prefix();

## **os\_disks()**

Returns a list of possible disks based on OS, prefixed by get\_disk\_prefix().

    my @disks = os_disks();

## **get\_smart\_cmd()**

Find the path to smartctl or quit.

    my $smart_cmd = get_smart_cmd();

## **get\_raid\_cmd()**

Find the path to lspci or return undef.

    my $raid_cmd = get_raid_cmd();

## **get\_raid\_flag()**

Find the raid flag for use with the current RAID.  Currently supports Highpoint and MegaRAID controllers.

    my $raid_flag = get_raid_flag();

## **get\_softraidtool\_cmd()**

Find the path to softraidtool or return undef.

    my $softraid_cmd = get_softraidtool_cmd();

## **get\_diskutil\_cmd()**

On MacOS, find the path to diskutil or return undef.

    my $diskutil_cmd = get_diskutil_cmd();

## **get\_physical\_disks()**

On MacOS, find the physical disks (not synthesized or disk image)

    my @disks = get_physical_disks();

## **get\_smart\_disks(@disks)**

Given a list of disks, find all disks that support SMART and return as a list

    my @smart_disks = get_smart_disks(@disks);

## **is\_drive\_smart($disk)**

Test if a disk supports SMART

    my $drive_is_smart = is_drive_smart($disk);

## **smart\_on\_for($disk)**

Test is SMART is enabled for a disk

    my $smart_enabled = smart_on_for($disk);

## **smart\_test\_for**

Run smart test on a disk, specify test\_type (short, long)

    $smart_test_started = smart_test_for($disk);

## **selftest\_history\_for**

Show the self-test history for a disk

    selftest_history_for($disk);

## **smart\_cmd\_for**

Run a smart command for a disk

    my $return_buffer_ref
        = smart_cmd_for(
                         { cmd_path => $cmd_path,
                           cmd_type => $cmd_type,
                           disk     => $current_disk
                         }
                       );

## **load\_local\_config(HOSTNAME)**

Load host local disk configuration from `$HOME/.smarttools.yml` if it exists.
This allows for manual configuration in the case where the automatic detection
of disks is not precise.

`HOSTNAME` host name specified in configuration file. 
Allows a single configuration file to be deployed with multiple host's configurations.

    my $local_config_ref = load_local_config($hostname);

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-disk-smarttools at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Disk-SmartTools](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Disk-SmartTools).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Disk::SmartTools

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Disk-SmartTools](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Disk-SmartTools)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Disk-SmartTools](https://cpanratings.perl.org/d/Disk-SmartTools)

- Search CPAN

    [https://metacpan.org/release/Disk-SmartTools](https://metacpan.org/release/Disk-SmartTools)

# ACKNOWLEDGMENTS

# LICENSE AND COPYRIGHT

This software is Copyright © 2024-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
