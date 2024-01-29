# NAME

FindBin - Locate directory of original Perl script

# SYNOPSIS

    use FindBin;
    use lib "$FindBin::Bin/../lib";

    use FindBin qw($Bin);
    use lib "$Bin/../lib";

# DESCRIPTION

Locates the full path to the script bin directory to allow the use
of paths relative to the bin directory.

This allows a user to setup a directory tree for some software with
directories `<root>/bin` and `<root>/lib`, and then the above
example will allow the use of modules in the lib directory without knowing
where the software tree is installed.

If `perl` is invoked using the `-e` option or the Perl script is read from
`STDIN`, then `FindBin` sets both `$Bin` and `$RealBin` to the current
directory.

# EXPORTABLE VARIABLES

- `$Bin` or `$Dir`

    Path to the bin **directory** from where script was invoked

- `$Script`

    **Basename** of the script from which `perl` was invoked

- `$RealBin` or `$RealDir`

    `$Bin` with all links resolved

- `$RealScript`

    `$Script` with all links resolved

You can also use the `ALL` tag to export all of the above variables together:

    use FindBin ':ALL';

# KNOWN ISSUES

If there are two modules using `FindBin` from different directories
under the same interpreter, this won't work. Since `FindBin` uses a
`BEGIN` block, it'll be executed only once, and only the first caller
will get it right. This is a problem under `mod_perl` and other persistent
Perl environments, where you shouldn't use this module. Which also means
that you should avoid using `FindBin` in modules that you plan to put
on CPAN. Call the `again` function to make sure that `FindBin` will work:

    use FindBin;
    FindBin::again(); # or FindBin->again;

In former versions of `FindBin` there was no `again` function.
The workaround was to force the `BEGIN` block to be executed again:

    delete $INC{'FindBin.pm'};
    require FindBin;

# AUTHORS

`FindBin` is supported as part of the core perl distribution.  Please submit bug
reports at [https://github.com/Perl/perl5/issues](https://github.com/Perl/perl5/issues).

Graham Barr <`gbarr@pobox.com`>
Nick Ing-Simmons <`nik@tiuk.ti.com`>

# COPYRIGHT

Copyright (c) 1995 Graham Barr & Nick Ing-Simmons. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
