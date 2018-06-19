# NAME

File::ShareDir - Locate per-dist and per-module shared files

<div>
    <a href="https://travis-ci.org/perl5-utils/File-ShareDir"><img src="https://travis-ci.org/perl5-utils/File-ShareDir.svg?branch=master" alt="Travis CI"/></a>
    <a href='https://coveralls.io/github/perl5-utils/File-ShareDir?branch=master'><img src='https://coveralls.io/repos/github/perl5-utils/File-ShareDir/badge.svg?branch=master' alt='Coverage Status' /></a>
    <a href="https://saythanks.io/to/rehsack"><img src="https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg" alt="Say Thanks" /></a>
</div>

# SYNOPSIS

    use File::ShareDir ':ALL';
    
    # Where are distribution-level shared data files kept
    $dir = dist_dir('File-ShareDir');
    
    # Where are module-level shared data files kept
    $dir = module_dir('File::ShareDir');
    
    # Find a specific file in our dist/module shared dir
    $file = dist_file(  'File-ShareDir',  'file/name.txt');
    $file = module_file('File::ShareDir', 'file/name.txt');
    
    # Like module_file, but search up the inheritance tree
    $file = class_file( 'Foo::Bar', 'file/name.txt' );

# DESCRIPTION

The intent of [File::ShareDir](https://metacpan.org/pod/File::ShareDir) is to provide a companion to
[Class::Inspector](https://metacpan.org/pod/Class::Inspector) and [File::HomeDir](https://metacpan.org/pod/File::HomeDir), modules that take a
process that is well-known by advanced Perl developers but gets a
little tricky, and make it more available to the larger Perl community.

Quite often you want or need your Perl module (CPAN or otherwise)
to have access to a large amount of read-only data that is stored
on the file-system at run-time.

On a linux-like system, this would be in a place such as /usr/share,
however Perl runs on a wide variety of different systems, and so
the use of any one location is unreliable.

Perl provides a little-known method for doing this, but almost
nobody is aware that it exists. As a result, module authors often
go through some very strange ways to make the data available to
their code.

The most common of these is to dump the data out to an enormous
Perl data structure and save it into the module itself. The
result are enormous multi-megabyte .pm files that chew up a
lot of memory needlessly.

Another method is to put the data "file" after the \_\_DATA\_\_ compiler
tag and limit yourself to access as a filehandle.

The problem to solve is really quite simple.

    1. Write the data files to the system at install time.
    
    2. Know where you put them at run-time.

Perl's install system creates an "auto" directory for both
every distribution and for every module file.

These are used by a couple of different auto-loading systems
to store code fragments generated at install time, and various
other modules written by the Perl "ancient masters".

But the same mechanism is available to any dist or module to
store any sort of data.

## Using Data in your Module

`File::ShareDir` forms one half of a two part solution.

Once the files have been installed to the correct directory,
you can use `File::ShareDir` to find your files again after
the installation.

For the installation half of the solution, see [File::ShareDir::Install](https://metacpan.org/pod/File::ShareDir::Install)
and its `install_share` directive.

Using [File::ShareDir::Install](https://metacpan.org/pod/File::ShareDir::Install) together with [File::ShareDir](https://metacpan.org/pod/File::ShareDir)
allows one to rely on the files in appropriate `dist_dir()`
or `module_dir()` in development phase, too.

# FUNCTIONS

`File::ShareDir` provides four functions for locating files and
directories.

For greater maintainability, none of these are exported by default
and you are expected to name the ones you want at use-time, or provide
the `':ALL'` tag. All of the following are equivalent.

    # Load but don't import, and then call directly
    use File::ShareDir;
    $dir = File::ShareDir::dist_dir('My-Dist');
    
    # Import a single function
    use File::ShareDir 'dist_dir';
    dist_dir('My-Dist');
    
    # Import all the functions
    use File::ShareDir ':ALL';
    dist_dir('My-Dist');

All of the functions will check for you that the dir/file actually
exists, and that you have read permissions, or they will throw an
exception.

## dist\_dir

    # Get a distribution's shared files directory
    my $dir = dist_dir('My-Distribution');

The `dist_dir` function takes a single parameter of the name of an
installed (CPAN or otherwise) distribution, and locates the shared
data directory created at install time for it.

Returns the directory path as a string, or dies if it cannot be
located or is not readable.

## module\_dir

    # Get a module's shared files directory
    my $dir = module_dir('My::Module');

The `module_dir` function takes a single parameter of the name of an
installed (CPAN or otherwise) module, and locates the shared data
directory created at install time for it.

In order to find the directory, the module **must** be loaded when
calling this function.

Returns the directory path as a string, or dies if it cannot be
located or is not readable.

## dist\_file

    # Find a file in our distribution shared dir
    my $dir = dist_file('My-Distribution', 'file/name.txt');

The `dist_file` function takes two parameters of the distribution name
and file name, locates the dist directory, and then finds the file within
it, verifying that the file actually exists, and that it is readable.

The filename should be a relative path in the format of your local
filesystem. It will simply added to the directory using [File::Spec](https://metacpan.org/pod/File::Spec)'s
`catfile` method.

Returns the file path as a string, or dies if the file or the dist's
directory cannot be located, or the file is not readable.

## module\_file

    # Find a file in our module shared dir
    my $dir = module_file('My::Module', 'file/name.txt');

The `module_file` function takes two parameters of the module name
and file name. It locates the module directory, and then finds the file
within it, verifying that the file actually exists, and that it is readable.

In order to find the directory, the module **must** be loaded when
calling this function.

The filename should be a relative path in the format of your local
filesystem. It will simply added to the directory using [File::Spec](https://metacpan.org/pod/File::Spec)'s
`catfile` method.

Returns the file path as a string, or dies if the file or the dist's
directory cannot be located, or the file is not readable.

## class\_file

    # Find a file in our module shared dir, or in our parent class
    my $dir = class_file('My::Module', 'file/name.txt');

The `module_file` function takes two parameters of the module name
and file name. It locates the module directory, and then finds the file
within it, verifying that the file actually exists, and that it is readable.

In order to find the directory, the module **must** be loaded when
calling this function.

The filename should be a relative path in the format of your local
filesystem. It will simply added to the directory using [File::Spec](https://metacpan.org/pod/File::Spec)'s
`catfile` method.

If the file is NOT found for that module, `class_file` will scan up
the module's @ISA tree, looking for the file in all of the parent
classes.

This allows you to, in effect, "subclass" shared files.

Returns the file path as a string, or dies if the file or the dist's
directory cannot be located, or the file is not readable.

# EXTENDING

## Overriding Directory Resolution

`File::ShareDir` has two convenience hashes for people who have advanced usage
requirements of `File::ShareDir` such as using uninstalled `share`
directories during development.

    #
    # Dist-Name => /absolute/path/for/DistName/share/dir
    #
    %File::ShareDir::DIST_SHARE

    #
    # Module::Name => /absolute/path/for/Module/Name/share/dir
    #
    %File::ShareDir::MODULE_SHARE

Setting these values any time before the corresponding calls

    dist_dir('Dist-Name')
    dist_file('Dist-Name','some/file');

    module_dir('Module::Name');
    module_file('Module::Name','some/file');

Will override the base directory for resolving those calls.

An example of where this would be useful is in a test for a module that
depends on files installed into a share directory, to enable the tests
to use the development copy without needing to install them first.

    use File::ShareDir;
    use Cwd qw( getcwd );
    use File::Spec::Functions qw( rel2abs catdir );

    $File::ShareDir::MODULE_SHARE{'Foo::Module'} = rel2abs(catfile(getcwd,'share'));

    use Foo::Module;

    # interal calls in Foo::Module to module_file('Foo::Module','bar') now resolves to
    # the source trees share/ directory instead of something in @INC

# SUPPORT

Bugs should always be submitted via the CPAN request tracker, see below.

You can find documentation for this module with the perldoc command.

    perldoc File::ShareDir

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ShareDir](http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ShareDir)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/File-ShareDir](http://annocpan.org/dist/File-ShareDir)

- CPAN Ratings

    [http://cpanratings.perl.org/s/File-ShareDir](http://cpanratings.perl.org/s/File-ShareDir)

- CPAN Search

    [http://search.cpan.org/dist/File-ShareDir/](http://search.cpan.org/dist/File-ShareDir/)

## Where can I go for other help?

If you have a bug report, a patch or a suggestion, please open a new
report ticket at CPAN (but please check previous reports first in case
your issue has already been addressed).

Report tickets should contain a detailed description of the bug or
enhancement request and at least an easily verifiable way of
reproducing the issue or fix. Patches are always welcome, too.

## Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

## Business support and maintenance

For business support you can contact the maintainer via his CPAN
email address. Please keep in mind that business support is neither
available for free nor are you eligible to receive any support
based on the license distributed with this package.

# AUTHOR

Adam Kennedy <adamk@cpan.org>

## MAINTAINER

Jens Rehsack <rehsack@cpan.org>

# SEE ALSO

[File::ShareDir::Install](https://metacpan.org/pod/File::ShareDir::Install),
[File::ConfigDir](https://metacpan.org/pod/File::ConfigDir), [File::HomeDir](https://metacpan.org/pod/File::HomeDir),
[Module::Install](https://metacpan.org/pod/Module::Install), [Module::Install::Share](https://metacpan.org/pod/Module::Install::Share),
[File::ShareDir::PAR](https://metacpan.org/pod/File::ShareDir::PAR), [Dist::Zilla::Plugin::ShareDir](https://metacpan.org/pod/Dist::Zilla::Plugin::ShareDir)

# COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy,
Copyright 2014 - 2018 Jens Rehsack.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.
