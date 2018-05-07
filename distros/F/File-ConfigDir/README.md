# NAME

File::ConfigDir - Get directories of configuration files

<div>
    <a href="https://travis-ci.org/perl5-utils/File-ConfigDir"><img src="https://travis-ci.org/perl5-utils/File-ConfigDir.svg?branch=master" alt="Travis CI"/></a>
    <a href='https://coveralls.io/github/perl5-utils/File-ConfigDir?branch=master'><img src='https://coveralls.io/repos/github/perl5-utils/File-ConfigDir/badge.svg?branch=master' alt='Coverage Status'/></a>
</div>

# SYNOPSIS

    use File::ConfigDir ':ALL';

    my @cfgdirs = config_dirs();
    my @appcfgdirs = config_dirs('app');

    # install support
    my $site_cfg_dir = (site_cfg_dir())[0];
    my $vendor_cfg_dir = (site_cfg_dir()))[0];

# DESCRIPTION

This module is a helper for installing, reading and finding configuration
file locations. It's intended to work in every supported Perl5 environment
and will always try to Do The Right Thing(TM).

`File::ConfigDir` is a module to help out when perl modules (especially
applications) need to read and store configuration files from more than
one location. Writing user configuration is easy thanks to
[File::HomeDir](https://metacpan.org/pod/File::HomeDir), but what when the system administrator needs to place
some global configuration or there will be system related configuration
(in `/etc` on UNIX(TM) or `$ENV{windir}` on Windows(TM)) and some
network configuration in NFS mapped `/etc/p5-app` or
`$ENV{ALLUSERSPROFILE} . "\\Application Data\\p5-app"`, respectively.

`File::ConfigDir` has no "do what I mean" mode - it's entirely up to the
user to pick the right directory for each particular application.

# EXPORT

Every function listed below can be exported, either by name or using the
tag `:ALL`.

# SUBROUTINES/METHODS

All functions can take one optional argument as application specific
configuration directory. If given, it will be embedded at the right (TM)
place of the resulting path.

## system\_cfg\_dir

Returns the configuration directory where configuration files of the
operating system resides. For Unices this is `/etc`, for MSWin32 it's
the value of the environment variable `%windir%`.

## machine\_cfg\_dir

Alias for desktop\_cfg\_dir - deprecated.

## xdg\_config\_dirs

Alias for desktop\_cfg\_dir

## desktop\_cfg\_dir

Returns the configuration directory where configuration files of the
desktop applications resides. For Unices this is `/etc/xdg`, for MSWin32
it's the value of the environment variable `%ALLUSERSPROFILE%`
concatenated with the basename of the environment variable `%APPDATA%`.

## core\_cfg\_dir

Returns the `etc` directory below `$Config{prefix}`.

## site\_cfg\_dir

Returns the `etc` directory below `$Config{sitelib_stem}` or the common
base directory of `$Config{sitelib}` and `$Config{sitebin}`.

## vendor\_cfg\_dir

Returns the `etc` directory below `$Config{vendorlib_stem}` or the common
base directory of `$Config{vendorlib}` and `$Config{vendorbin}`.

## singleapp\_cfg\_dir

Returns the configuration file for stand-alone installed applications. In
Unix speak, installing JRE to `/usr/local/jre-<version>` means there is
a `/usr/local/jre-<version>/bin/java` and going from it's directory
name one above and into `etc` there is the _singleapp\_cfg\_dir_. For a
Perl module it means, we're assuming that `$FindBin::Bin` is installed as
a stand-alone package somewhere, e.g. into `/usr/pkg` - as recommended for
[pkgsrc](http://www.pkgsrc.org/).

## vendorapp\_cfg\_dir

Returns the configuration file for vendor installed applications. In Unix
speak, installing bacula to `/opt/${vendor}` means there is
a `/opt/${vendor}/bin/bacula` and going from it's directory
name one above and into `etc` there is the _vendorapp\_cfg\_dir_. For a
Perl module it means, we're assuming that `$FindBin::Bin` is installed as
a stand-alone package somewhere, e.g. into `/usr/pkg` - as recommended for
[pkgsrc](http://www.pkgsrc.org/).

## local\_cfg\_dir

Returns the configuration directory for distribution independent, 3rd
party applications. While this directory doesn't exists for MSWin32,
there will be only the path `/usr/local/etc` for Unices.

## locallib\_cfg\_dir

Extracts the `INSTALL_BASE` from `$ENV{PERL_MM_OPT}` and returns the
`etc` directory below it.

## here\_cfg\_dir

Returns the path for the `etc` directory below the current working directory.

## user\_cfg\_dir

Returns the users home folder using [File::HomeDir](https://metacpan.org/pod/File::HomeDir). Without
File::HomeDir, nothing is returned.

## xdg\_config\_home

Returns the user configuration directory for desktop applications.
If `$ENV{XDG_CONFIG_HOME}` is not set, for MSWin32 the value
of `$ENV{APPDATA}` is return and on Unices the `.config` directory
in the users home folder. Without [File::HomeDir](https://metacpan.org/pod/File::HomeDir), on Unices the returned
list might be empty.

## config\_dirs

    @cfgdirs = config_dirs();
    @cfgdirs = config_dirs( 'appname' );

Tries to get all available configuration directories as described above.
Returns those who exists and are readable.

## \_plug\_dir\_source

    my $dir_src = sub { return _better_config_dir(@_); }
    File::ConfigDir::_plug_dir_source($dir_src);

    my $pure_src = sub { return _better_config_plain_dir(@_); }
    File::ConfigDir::_plug_dir_source($pure_src, 1); # see 2nd arg is true

Registers more sources to ask for suitable directories to check or search
for config files. Each ["config\_dirs"](#config_dirs) will traverse them in subsequent
invocations, too.

Returns the number of directory sources in case of success. Returns nothing
when `$dir_src` is not a code ref.

# AUTHOR

Jens Rehsack, `<rehsack at cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-File-ConfigDir at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ConfigDir](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ConfigDir).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::ConfigDir

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ConfigDir](http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ConfigDir)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/File-ConfigDir](http://annocpan.org/dist/File-ConfigDir)

- CPAN Ratings

    [http://cpanratings.perl.org/d/File-ConfigDir](http://cpanratings.perl.org/d/File-ConfigDir)

- Search CPAN

    [http://search.cpan.org/dist/File-ConfigDir/](http://search.cpan.org/dist/File-ConfigDir/)

# ACKNOWLEDGEMENTS

Thanks are sent out to Lars Dieckow (daxim) for his suggestion to add
support for the Base Directory Specification of the Free Desktop Group.
Matthew S. Trout (mst) earns the credit to suggest `singleapp_cfg_dir`
and remind about `/usr/local/etc`.

# LICENSE AND COPYRIGHT

Copyright 2010-2018 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

# SEE ALSO

[File::HomeDir](https://metacpan.org/pod/File::HomeDir), [File::ShareDir](https://metacpan.org/pod/File::ShareDir), [File::BaseDir](https://metacpan.org/pod/File::BaseDir) (Unices only)
