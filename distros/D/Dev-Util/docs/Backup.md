# NAME

Dev::Util::Backup - Simple backup functions for files and dirs

# VERSION

Version v2.19.35

# SYNOPSIS

The backup function will make a copy of a file or dir with the date of the file appended.
It returns the name of the new file.  Directories are backed up by `tar` and `gz`.

    use Dev::Util::Backup qw(backup);

    my $backup_file = backup('myfile');
    say $backup_file;

    my $backup_dir = backup('mydir/');
    say $backup_dir;

Will produce:

    myfile_20251025
    mydir_20251025.tar.gz

If the file has changed, calling `backup('myfile')` again will create `myfile_20251025_1`.
Each time `backup` is called the appended counter will increase by 1 if `myfile` has
changed since the last time it was called.

If the file has not changed, no new backup will be created.

## Examples

The `bu` program in the examples dir will take a list of files and dirs as args and make
backups of them using `backup`.

# EXPORT

    backup

# SUBROUTINES

## **backup(FILE|DIR)**

Return the name of the backup file.

    my $backup_file = backup('myfile');
    my $backup_dir = backup('mydir/');

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-dev-util at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util).  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::Backup

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util)

- Search CPAN

    [https://metacpan.org/release/Dev-Util](https://metacpan.org/release/Dev-Util)

# ACKNOWLEDGMENTS

# LICENSE AND COPYRIGHT

This software is Copyright © 2001-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
