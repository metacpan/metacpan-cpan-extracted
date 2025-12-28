package Dev::Util;

use 5.018;
use strict;
use warnings;
use version;
use Carp qw(carp);

our $VERSION = version->declare("v2.19.33");

use Exporter   qw( );
use List::Util qw( uniq );

our @EXPORT      = ();
our @EXPORT_OK   = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );    # Optional.

sub import {
    my $class = shift;
    my (@packages) = @_;

    my ( @pkgs, @rest );
    for (@packages) {
        if (/^::/) {
            push @pkgs, __PACKAGE__ . $_;
        }
        else {
            push @rest, $_;
        }
    }

    for my $pkg (@pkgs) {
        my $mod = ( $pkg =~ s{::}{/}gr ) . ".pm";
        require $mod;

        my $exports = do { no strict "refs"; \@{ $pkg . "::EXPORT_OK" } };
        $pkg->import(@$exports);
        @EXPORT    = uniq @EXPORT,    @$exports;
        @EXPORT_OK = uniq @EXPORT_OK, @$exports;
    }

    @_ = ( $class, @rest );
    goto &Exporter::import;
}

1;    # End of Dev::Util

=pod

=encoding utf-8

=head1 NAME

Dev::Util - Utilities useful in the development of perl programs

=head1 VERSION

Version v2.19.33

=head1 SYNOPSIS

This module provides a standard set of tools to use for oft needed functionality.

Consistent feature setup is achieved.
Standard constants are defined. OS identification and external executables are
accessible. Quick backups can be made. File and directory attributes are discovered.
Lock files are created.

The sub-modules provide this and other utility functionality.

=head1 SUB-MODULES

The sub-modules provide the functionality described below.  For more details
see C<<< perldoc <Sub-module_Name> >>>.


=head2 Dev::Util

C<Dev::Util> provides a loader for sub-modules where a leading C<::> denotes
a package to load.

    use Dev::Util qw( ::File ::OS );

This is equivalent to:

    use Dev::Util::File qw(:all);
    use Dev::Util::OS   qw(:all);

=cut

# =head2 How it works

# The Dev::Util module simply imports functions from Dev::Util::*
# modules.  Each module defines a self-contained functions, and puts
# those function names into @EXPORT.  Dev::Util defines its own
# import function, but that does not matter to the plug-in modules.

# This function is taken from brian d foy's Test::Data module. Thanks brian!

=head2 Dev::Util::Syntax

Provide consistent feature setup. Put all of the "use" setup cmds in one
place. Then import them into other modules.  Changes are made in one place, yet apply
to all of the programs that use C<Dev::Util::Syntax>

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

B<Note: C<use Dev::Util::Syntax> automatically adds C<use strict> and C<use warnings> to the program.>

L<Dev::Util::Syntax>

=head2 Dev::Util::Const

Defines named constants as Readonly, based on best practices.

    $EMPTY_STR = q{};
    $SPACE = q{ };
    $SINGLE_QUOTE = q{'};
    $DOUBLE_QUOTE = q{"};
    $COMMA = q{,};

L<Dev::Util::Const>

=head2 Dev::Util::OS

OS discovery and functions to execute and collect data from external programs.

    use Dev::Util::OS;

    my $OS = get_os();
    my $hostname = get_hostname();
    my $system_is_linux = is_linux();
    my @seq = ipc_run_c( { cmd => 'seq 1 10', } );

L<Dev::Util::OS>

=head2 Dev::Util::File

Provides functions to assist working with files and dirs, menus and prompts.

    use Dev::Util::File;

    my $fexists     = file_exists('/path/to/somefile');
    my $canwritef   = file_writable('/path/to/somefile');
    my $isplainfile = file_is_plain('/path/to/somefile');
    my $issymlink   = file_is_symbolic_link('/path/to/somefile');
    my $canreadd    = dir_readable('/path/to/somedir');
    my $slash_added_dir = dir_suffix_slash('/dir/path/no/slash');
    my $td = mk_temp_dir();

L<Dev::Util::File>

=head2 Dev::Util::Query

Provides functions to ask the user for input.

    banner( "Hello World", $outputFH );
    display_menu( $msg, \@items );
    my $action = yes_no_prompt( { text    => "Rename Files?", default => 1, });

L<Dev::Util::Query>

=head2 Dev::Util::Backup

The backup function will make a copy of a file or dir with the date of the file
appended. Directories are backed up by tar and gz.

    my $backup_file = backup('myfile');
    my $backup_dir  = backup('mydir/');

L<Dev::Util::Backup>

=head2 Dev::Util::Sem

Module to do Semaphore locking

    use Dev::Util::Sem;

    my $sem = Sem->new('mylock.sem');
    ...
    $sem->unlock;

L<Dev::Util::Sem>

=head1 EXAMPLES

Example programs that demonstrate how the C<Dev::Util> modules can be used are in the C<examples> dir.


=head1 SEE ALSO

L<Dev::Util::Backup>,
L<Dev::Util::Const>,
L<Dev::Util::File>,
L<Dev::Util::OS>,
L<Dev::Util::Query>
L<Dev::Util::Syntax>,
L<Dev::Util::Sem>,


=head1 AUTHOR

Matt Martini, C<< <matt.martini at imaginarywave.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dev-util at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 INSTALLATION

To install this module, see F<INSTALL.md>

TLDR; run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util>

=item * Search CPAN

L<https://metacpan.org/release/Dev-Util>

=back

=head1 HISTORY

This module was originally developed under the name C<MERM::Base>.


=head1 TEMPLATE

    module-starter \
        --module=Dev::Util \
        --module=Dev::Util::Backup \
        --module=Dev::Util::Const \
        --module=Dev::Util::File \
        --module=Dev::Util::OS \
        --module=Dev::Util::Query \
        --module=Dev::Util::Sem \
        --module=Dev::Util::Syntax \
        --builder=ExtUtils::MakeMaker \
        --author='Matt Martini' \
        --email=matt@imaginarywave.com \
        --ignore=git \
        --license=gpl3 \
        --genlicense \
        --minperl=5.018 \
        --verbose

=head1 ACKNOWLEDGMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright © 2024-2025 by Matt Martini.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

