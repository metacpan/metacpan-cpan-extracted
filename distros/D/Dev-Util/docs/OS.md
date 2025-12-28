# NAME

Dev::Util::OS - OS discovery and functions

# VERSION

Version v2.19.33

# SYNOPSIS

OS discovery and functions

    use Disk::SmartTools::OS;

    my $OS = get_os();
    my $hostname = get_hostname();
    my $system_is_linux = is_linux();
    ...
    my $status = ipc_run_e( { cmd => 'echo hello world', buf => \$buf } );
    my @seq = ipc_run_c( { cmd => 'seq 1 10', } );

# EXPORT

    get_os
    get_hostname
    is_linux
    is_mac
    is_freebsd
    is_openbsd
    is_sunos
    ipc_run_e
    ipc_run_c

# SUBROUTINES

## **get\_os**

Return the OS of the current system.

    my $OS = get_os();

## **get\_hostname**

Return the hostname of the current system.

    my $hostname = get_hostname();

## **is\_linux**

Return true if the current system is Linux.

    my $system_is_linux = is_linux();

## **is\_mac**

Return true if the current system is MacOS (Darwin).

    my $system_is_macOS = is_mac();

## **is\_freebsd**

Return true if the current system is FreeBSD.

    my $system_is_FreeBSD = is_freebsd();

## **is\_openbsd**

Return true if the current system is OpenBSD.

    my $system_is_OpenBSD = is_openbsd();

## **is\_sunos**

Return true if the current system is SunOS.

    my $system_is_sunOS = is_sunos();

## **ipc\_run\_e(ARGS\_HASH)**

Execute an external program and return the status of it's execution.

**ARGS\_HASH:**
{ cmd => CMD, buf => BUFFER\_REF, verbose => VERBOSE\_BOOL, timeout => SECONDS, debug => DEBUG\_BOOL }

`CMD` The external command to execute

`BUFFER_REF` A reference to a buffer

`VERBOSE_BOOL:optional` 1 (default) for verbose output, 0 not so much

`SECONDS:optional` number of seconds to wait for CMD to execute, default: 10 sec

`DEBUG_BOOL: optional` Debug flag, default: 0

    my $status = ipc_run_e( { cmd => 'echo hello world', verbose => 1, timeout => 8 } );

## **ipc\_run\_c(ARGS\_HASH)**

Capture the output of an external program.  Return the output or return undef on failure.

**ARGS\_HASH:**
{ cmd => CMD, buf => BUFFER\_REF, verbose => VERBOSE\_BOOL, timeout => SECONDS, debug => DEBUG\_BOOL }

    my @seq = ipc_run_c( { cmd => 'seq 1 10', } );

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-dev-util at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util).  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::OS

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util)

- Search CPAN

    [https://metacpan.org/release/Dev-Util](https://metacpan.org/release/Dev-Util)

# ACKNOWLEDGMENTS

# LICENSE AND COPYRIGHT

This software is Copyright © 2019-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
