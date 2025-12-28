# NAME

Dev::Util::Const - Defines named constants as Readonly.

# VERSION

Version v2.19.33

# SYNOPSIS

Dev::Util::Const - Defines named constants as Readonly, based on best practices.
This idea comes from **Perl Best Practices** by Damian Conway _pg. 56_.

    use Dev::Util::Const;
    my $empty_var = $EMPTY_STR;
    my $comma     = $COMMA;

    use Dev::Util::Const qw(:named_constants);
    my $space = $SPACE;
    my $single_quote = $SINGLE_QUOTE;

    use Dev::Util::Const qw($DOUBLE_QUOTE);  # only import a single constant.
    my $double_quote = $DOUBLE_QUOTE;

## Note

The purpose of this module is to define the named constants.  As such the constants
are exported by default.

The second and third examples above work but at the present time are superfluous. They
are retained for future expansion.

# EXPORT\_TAGS

- **:named\_constants**
    - $EMPTY\_STR
    - $SPACE
    - $SINGLE\_QUOTE
    - $DOUBLE\_QUOTE
    - $COMMA

# CONSTANTS

These constants are defined as readonly:

- `$EMPTY_STR = q{};`
- `$SPACE = q{ };`
- `$SINGLE_QUOTE = q{'};`
- `$DOUBLE_QUOTE = q{"};`
- `$COMMA = q{,};`

# SUBROUTINES

There are no public subroutines.

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-dev-util at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util).  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::Const

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
