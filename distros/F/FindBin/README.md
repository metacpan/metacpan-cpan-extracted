# NAME

FindBin - Locate directory of original perl script

# SYNOPSIS

    use FindBin;
    use lib "$FindBin::Bin/../lib";

    or

    use FindBin qw($Bin);
    use lib "$Bin/../lib";

# DESCRIPTION

Locates the full path to the script bin directory to allow the use
of paths relative to the bin directory.

This allows a user to setup a directory tree for some software with
directories `<root>/bin` and `<root>/lib`, and then the above
example will allow the use of modules in the lib directory without knowing
where the software tree is installed.

If perl is invoked using the **-e** option or the perl script is read from
`STDIN` then FindBin sets both `$Bin` and `$RealBin` to the current
directory.

# EXPORTABLE VARIABLES

    $Bin         - path to bin directory from where script was invoked
    $Script      - basename of script from which perl was invoked
    $RealBin     - $Bin with all links resolved
    $RealScript  - $Script with all links resolved

# KNOWN ISSUES

If there are two modules using `FindBin` from different directories
under the same interpreter, this won't work. Since `FindBin` uses a
`BEGIN` block, it'll be executed only once, and only the first caller
will get it right. This is a problem under mod\_perl and other persistent
Perl environments, where you shouldn't use this module. Which also means
that you should avoid using `FindBin` in modules that you plan to put
on CPAN. To make sure that `FindBin` will work is to call the `again`
function:

    use FindBin;
    FindBin::again(); # or FindBin->again;

In former versions of FindBin there was no `again` function. The
workaround was to force the `BEGIN` block to be executed again:

    delete $INC{'FindBin.pm'};
    require FindBin;

# AUTHORS

FindBin is supported as part of the core perl distribution. Please send bug
reports to <`perlbug@perl.org`> using the perlbug program
included with perl.

Graham Barr <`gbarr@pobox.com`>
Nick Ing-Simmons <`nik@tiuk.ti.com`>

# COPYRIGHT

Copyright (c) 1995 Graham Barr & Nick Ing-Simmons. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
