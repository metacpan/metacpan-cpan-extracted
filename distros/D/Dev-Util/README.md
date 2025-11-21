# NAME
Dev::Util - Utilities useful in the development of perl programs

# VERSION
Version v2.19.11

# SYNOPSIS

This module provides a standard set of tools to use for oft needed functionality.  
Consistent feature setup is achieved.
Standard constants are defined. OS identification and external executables are accessible. 
Quick backups can be made. File and directory attributes are discovered. 

The sub-modules provide this and other utility functionality.

# SUB-MODULES
The sub-modules provide the functionality described below.  For more details see `perldoc <Sub-module_Name>`.

## Dev::Util
`Dev::Util` provides a loader for sub-modules where a leading `::` denotes a package to load.

    use Dev::Util qw( ::File ::OS );

This is equivalent to:

    use Dev::Util::File qw(:all);
    use Dev::Util::OS   qw(:all);

## Dev::Util::Syntax
Provide consistent feature setup. Put all of the "use" setup cmds in one
place. Then import them into other modules.  Changes are made in one place, yet apply
to all of the programs that use `Dev::Util::Syntax`

Use this in other modules:

    package My::Module::Example;

    use Dev::Util::Syntax;

    # Rest of Code...

This is equivalent to:

    package My::Module::Example;

    use feature :5.18;
    use utf8;
    use strict;
    use warnings;
    use autodie;
    use open qw(:std :utf8);
    use version;
    use Readonly;
    use Carp;
    use English qw( -no_match_vars );

    # Rest of Code...

**Note: `use Dev::Util::Syntax` automatically adds `use strict` and `use warnings` to the program.**

## Dev::Util::Const
Defines named constants as Readonly, based on best practices.

    $EMPTY_STR = q{};
    $SPACE = q{ };
    $SINGLE_QUOTE = q{'};
    $DOUBLE_QUOTE = q{"};
    $COMMA = q{,};

## Dev::Util::OS
OS discovery and functions to execute and collect data from external programs.

    use Dev::Util::OS;

    my $OS = get_os();
    my $hostname = get_hostname();
    my $system_is_linux = is_linux();
    my @seq = ipc_run_c( { cmd => 'seq 1 10', } );

## Dev::Util::File
Provides functions to assist working with files and dirs, menus and prompts.

    use Dev::Util::File;

    my $fexists     = file_exists('/path/to/somefile');
    my $canwritef   = file_writable('/path/to/somefile');
    my $isplainfile = file_is_plain('/path/to/somefile');
    my $issymlink   = file_is_symbolic_link('/path/to/somefile');
    my $canreadd    = dir_readable('/path/to/somedir');
    my $slash_added_dir = dir_suffix_slash('/dir/path/no/slash');
    my $td = mk_temp_dir();

## Dev::Util::Query
Provides functions to ask the user for input.

    banner( "Hello World", $outputFH );
    display_menu( $msg, \@items );
    my $action = yes_no_prompt( { text    => "Rename Files?", default => 1, });

## Dev::Util::Backup
The backup function will make a copy of a file or dir with the date of the file
appended. Directories are backed up by tar and gz.

    my $backup_file = backup('myfile');
    my $backup_dir  = backup('mydir/');

## Dev::Util::Sem
Module to do Semaphore locking

    use Dev::Util::Sem;

    my $sem = Sem->new('mylock.sem');
    ...
    $sem->unlock;

# EXAMPLES
Example programs demonstrate how the `Dev::Util` modules can be used are in the `examples` dir.


# INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Dev::Util

You can also look for information at:

- [RT, CPAN's request tracker (report bugs here)](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util)

- [Search CPAN](https://metacpan.org/release/Dev-Util)

# HISTORY
This module was originally developed under the name `MERM::Base`.

# TEMPLATE

    module-starter \
        --module=Dev::Util \
        --module=Dev::Util::Backup \
        --module=Dev::Util::Const \
        --module=Dev::Util::File \
        --module=Dev::Util::OS \
        --module=Dev::Util::Query \
        --module=Dev::Util::Syntax \
        --builder=ExtUtils::MakeMaker \
        --author='Matt Martini' \
        --email=matt@imaginarywave.com \
        --ignore=git \
        --license=gpl3 \
        --genlicense \
        --minperl=5.018 \
        --verbose

# LICENSE AND COPYRIGHT

This software is Copyright © 2001-2025 by Matt Martini.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

