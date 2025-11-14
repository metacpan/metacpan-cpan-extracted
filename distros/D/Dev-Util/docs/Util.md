# NAME

Dev::Util - Base modules for Perl Development

# VERSION

Version v2.18.19

# SYNOPSIS

Dev::Util provides a loader for sub-modules where a leading :: denotes a package to load.

    use Dev::Util qw( ::OS ::Utils );

This is equivalent to:

    user Dev::Util::OS    qw(:all);
    user Dev::Util::Utils qw(:all);

# SUBROUTINES/METHODS

Modules do specific functions.  Load as necessary.

# SEE ALSO

[Dev::Util::Backup](https://metacpan.org/pod/Dev%3A%3AUtil%3A%3ABackup),
[Dev::Util::Const](https://metacpan.org/pod/Dev%3A%3AUtil%3A%3AConst),
[Dev::Util::File](https://metacpan.org/pod/Dev%3A%3AUtil%3A%3AFile),
[Dev::Util::OS](https://metacpan.org/pod/Dev%3A%3AUtil%3A%3AOS),
[Dev::Util::Query](https://metacpan.org/pod/Dev%3A%3AUtil%3A%3AQuery)
[Dev::Util::Syntax](https://metacpan.org/pod/Dev%3A%3AUtil%3A%3ASyntax),

# AUTHOR

Matt Martini,  `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-dev-util at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util)

- Search CPAN

    [https://metacpan.org/release/Dev-Util](https://metacpan.org/release/Dev-Util)

# ACKNOWLEDGMENTS

# LICENSE AND COPYRIGHT

This software is Copyright © 2024-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
