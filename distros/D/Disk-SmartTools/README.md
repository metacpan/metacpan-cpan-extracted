# NAME
Disk::SmartTools - Provide tools to work with disks via S.M.A.R.T.

# VERSION
Version v3.3.16

# SYNOPSIS

This module provides tools to access the S.M.A.R.T. features of a system's disks.
It will allow the collection of information on the installed disks and *RAID* arrays.
Queries via `smartctl` will gather the current attributes of the disks.  Internal 
tests of the disks can be initiated.  

# SUB-MODULES
The sub-modules provide the functionality described below.  For more details see `perldoc <Sub-module_Name>`.

## Disk::SmartTools
This module provides the disk related functions.

    use Disk::SmartTools;

    my $smart_cmd = get_smart_cmd();
    my @disks = os_disks();
    my @smart_disks = get_smart_disks(@disks);
    $smart_test_started = smart_test_for($disk);
    my $local_config_ref = load_local_config($hostname);

# EXAMPLES
Two example programs demonstrate how the `Disk::SmartTools` modules can be used.

## smart_show.pl
Display SMART information on disks.

    $ smart_show.pl

Asks for the type of SMART information to display then reports for each
physical disk in the system.

    Display SMART information
    --------------------------
    Choose attribute to display:
         a. All SMART Info
         b. Info
         c. Overall-Health
         d. SelfTest History
         e. Error Log
         f. Temperature Graph
         g. Power_On_Hours
         h. Power_Cycle_Count
         i. Temperature_Celsius
         j. Reallocated_Sector_Ct
         k. Offline_Uncorrectable
         l. Raw_Read_Error_Rate
         m. Seek_Error_Rate
         n. Reported_Uncorrect
         o. Command_Timeout
         p. Current_Pending_Sector

For more information:

    perldoc smart_show.pl

## smart_run_tests.pl
Runs a SMART test on all disks.  Typically run as a crontab.

    $ smart_run_tests.pl <args>

    --test_type : Length of SMART test, short (default) or long
    --dry_run : Don't actually perform SMART test
    --debug : Turn debugging on
    --verbose : Generate debugging info on stderr
    --silent : Do not print report on stdout
    --help : This helpful information.
    
For more information:

    perldoc smart_run_test.pl

# INSTALLATION
To install this module, follow the instructions in `INSTALL.md`

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Disk::SmartTools

You can also look for information at:

- [RT, CPAN's request tracker (report bugs here)](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Disk-SmartTools)

- [Search CPAN](https://metacpan.org/release/Disk-SmartTools)

# HISTORY
This module was originally developed under the name `MERM::SmartTools`.

# TEMPLATE

    module-starter \
            --module=Disk::SmartTools \
            --builder=ExtUtils::MakeMaker \
            --author='Matt Martini' \
            --email=matt@imaginarywave.com \
            --ignore=git \
            --license=gpl3 \
            --genlicense \
            --minperl=5.018 \
            --verbose

# LICENSE AND COPYRIGHT

This software is Copyright © 2020-2025 by Matt Martini.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

