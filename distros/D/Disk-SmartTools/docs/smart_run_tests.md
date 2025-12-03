# NAME

smart\_run\_tests.pl - Runs a SMART test on all disks.

# SYNOPSIS

Runs a SMART test on each physical disk in the system.
Distributed in Disk::SmartTools.

Can run either short or long SMART test on each disk.

- smart\_run\_tests.pl &lt;args>
- --test\_type  : Length of SMART test, short (default) or long
- --dry\_run    : Don't actually perform SMART test
- --debug      : Turn debugging on
- --verbose    : Generate debugging info on stderr
- --silent     : Do not print report on stdout
- --help       : This helpful information.

**Must be run as root.**

## Crontabs

Usually run as a crontab.  Note the `--long` option is safe to run everyday, it
will only run the long test on (up to) one disk a day.  By hashing the day of
the month with the disk index it will run once a month for each disk.

- 30 5 \* \* \*       : S.M.A.R.T. disk checks - short ; /var/root/bin/smart\_run\_tests.pl



- 4  6 \* \* \*       : S.M.A.R.T. disk checks - long  ; /var/root/bin/smart\_run\_tests.pl --test\_type=long

# REQUIREMENTS

This program depends on Disk::SmartTools.

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-merm-smarttools at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Disk-SmartTools](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Disk-SmartTools).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# LICENSE AND COPYRIGHT

This software is Copyright © 2024-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
