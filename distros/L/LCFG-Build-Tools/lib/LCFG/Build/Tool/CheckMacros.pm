package LCFG::Build::Tool::CheckMacros;    # -*-perl-*-
use strict;
use warnings;

# $Id: CheckMacros.pm.in 35684 2019-02-28 10:04:54Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tool/CheckMacros.pm.in,v $
# $Revision: 35684 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Tool/CheckMacros.pm.in $
# $Date: 2019-02-28 10:04:54 +0000 (Thu, 28 Feb 2019) $

our $VERSION = '0.9.30';

use File::Spec ();
use File::Temp ();
use IO::File ();
use LCFG::Build::Utils;

use Moose;

extends 'LCFG::Build::Tool';

# We do not want this option for these commands so use an override.

has '+resultsdir' => ( traits => ['NoGetopt'] );

has 'fix_deprecated' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Replace deprecated macros with new-style names',
);

__PACKAGE__->meta->make_immutable;

sub abstract {
    return q{Check for correct macro usage};
}

my %messages = (
    unknown    => 'Use of unknown macro',
    deprecated => 'Use of deprecated macro',
    linux      => 'Use of linux-only macro',
    macosx     => 'Use of MacOSX-only macro',
    buildtime  => 'Use of build-time-only macro',
);

my %basic = map { $_ => 'basic' } qw(
    LCFG_ABSTRACT
    LCFG_NAME
    LCFG_FULLNAME
    LCFG_VERSION
    LCFG_VERSION
    LCFG_PERL_VERSION
    LCFG_RELEASE
    LCFG_SCHEMA
    LCFG_VENDOR
    LCFG_GROUP
    LCFG_AUTHOR
    LCFG_PLATFORMS
    LCFG_DATE
    LCFG_LICENSE
    LCFG_TARNAME
    LCFG_CHANGELOG
    BOOTSTAMP
    INITDIR
    LCFGBIB
    LCFGBIN
    LCFGCLIENTDEF
    LCFGCOMP
    LCFGCONF
    LCFGCONFIGMSG
    LCFGDATA
    LCFGDOC
    LCFGHTML
    LCFGLIB
    LCFGLOCK
    LCFGLOG
    LCFGMAN
    LCFGOM
    LCFGPDF
    LCFGPOD
    LCFGROTATED
    LCFGSBIN
    LCFGSERVERDEF
    LCFGSTATUS
    LCFGRUN
    LCFGTMP
    LCFGVAR
    LIBMANDIR
    LIBMANSECT
    MANDIR
    MANSECT
    RELEASEFILE
);

my %deprecated = (
    COMP          => 'LCFG_NAME',
    NAME          => 'LCFG_FULLNAME',
    DESCR         => 'LCFG_ABSTRACT',
    V             => 'LCFG_VERSION',
    VERSION       => 'LCFG_VERSION',
    R             => 'LCFG_RELEASE',
    RELEASE       => 'LCFG_RELEASE',
    SCHEMA        => 'LCFG_SCHEMA',
    VENDOR        => 'LCFG_VENDOR',
    ORGANIZATION  => 'LCFG_VENDOR',
    GROUP         => 'LCFG_GROUP',
    AUTHOR        => 'LCFG_AUTHOR',
    PLATFORMS     => 'LCFG_PLATFORMS',
    DATE          => 'LCFG_DATE',
    TARFILE       => 'LCFG_TARNAME',
);

my %buildtime = map { $_ => 'buildtime' } qw(
    HAS_PROC
    BOOTCOMP
    PERL
    PERL_EXECUTABLE
    PERL_INSTALLDIRS
    PERL_ARCHDIR
    PERL_LIBDIR
    SHELL
    EGREP
    SED
    SORT
    LCFGOS
    LCFGARCH
    MSG
    CONFIGDIR
    ICONDIR
    SCRIPTDIR
    LCFG_TMPLDIR
);

my %linux = map { $_ => 'linux' } qw(
    LSB_VERSION
    DISTRIB_ID
    DISTRIB_DESCRIPTION
    DISTRIB_RELEASE
    DISTRIB_CODENAME
    OS_VERSION
    OS_RELEASE
    LIBDIR
    LIBSECURITYDIR
);

my %macosx = map { $_ => 'macosx' } qw(
    OSX_VERSION
);

sub complain {
    my ( $self, $msg, $macro, @where ) = @_;

    print "$msg, $macro, at: \n";
    for my $where (@where) {
        print "\t$where\n";
    }

    return;
}

sub execute {
    my ($self) = @_;

    my $dir       = $self->dir;
    my @translate = $self->spec->translate;

    my %files = LCFG::Build::Utils::find_trans_files( $dir, @translate,
        'specfile' );

    my %macros_found;
    for my $file ( keys %files ) {
        my $path = File::Spec->catfile( $dir, $file );
        my $fh = IO::File->new( $path, 'r' )
            or $self->fail("Could not open $path: $!");

        my $count = 0;
        while ( defined( my $line = $fh->getline ) ) {
            $count++;

            my @macros = (
                $line =~ m{\@
                           (\w+)        # The macro name
                           \@}gx
            );

            # unique-ify
            my %macros = map { $_ => 1 } @macros;
            @macros = keys %macros;

            for my $macro (@macros) {
                if ( exists $macros_found{$macro} ) {
                    push @{ $macros_found{$macro} }, "$file:$count";
                }
                else {
                    $macros_found{$macro} = ["$file:$count"];
                }
            }
        }
    }

    # Collate the results

    my %comments;
    for my $macro ( keys %macros_found ) {

        if ( $basic{$macro} ) {

            # ok
        }
        elsif ( $deprecated{$macro} ) {
            $comments{deprecated}{$macro} = $macros_found{$macro};
        }
        elsif ( $buildtime{$macro} ) {
            $comments{buildtime}{$macro} = $macros_found{$macro};
        }
        elsif ( $linux{$macro} ) {
            $comments{linux}{$macro} = $macros_found{$macro};
        }
        elsif ( $macosx{$macro} ) {
            $comments{macosx}{$macro} = $macros_found{$macro};
        }
        else {
            $comments{unknown}{$macro} = $macros_found{$macro};
        }
    }

    # Make the report

    for my $key (qw/unknown deprecated linux macosx buildtime/) {
        if ( exists $comments{$key} && ref $comments{$key} eq 'HASH' ) {
            for my $macro ( sort keys %{ $comments{$key} } ) {
                $self->complain( $messages{$key}, $macro,
                    @{ $comments{$key}{$macro} } );
            }
        }
    }

    if ( $self->fix_deprecated ) {
        my %files_using_deprecated;
        for my $macro ( keys %{$comments{deprecated}} ) {
            my @found = @{$comments{deprecated}{$macro}};
            for my $entry (@found) {
                if ( $entry =~ m/^(.*?):\d+$/ ) {
                    $files_using_deprecated{$1} = 1;
                }
            }
        }

        if ( 0 == scalar keys %files_using_deprecated ) {
            $self->log("No deprecated macro usage found.");
        }

        for my $file ( sort keys %files_using_deprecated ) {
            $self->log("Fixing deprecated macros in $file");

            my $path = File::Spec->catfile( $dir, $file );
            my $in = IO::File->new( $path, 'r' )
                or $self->fail("Could not open $path: $!");

            my $tmp = File::Temp->new( UNLINK => 0,
                                       DIR    => $dir );

            while ( defined( my $line = <$in> ) ) {

                # Find a unique list of macros in this line

                my @macros = ( $line =~ m/\@(\w+)\@/g );
                my %macros = map { $_ => 1 } @macros;
                @macros = keys %macros;

                for my $macro (@macros) {
                    if ( exists $deprecated{$macro} ) {
                        $line =~ s/\@\Q$macro\E\@/\@$deprecated{$macro}\@/g;
                    }
                }

                print {$tmp} $line;
            }

            my $out = $tmp->filename;
            $tmp->close or $self->fail("Could not close $out: $!");

            if ( !$self->dryrun ) {
                rename $out, $path
                    or $self->fail("Could not move $out to $path: $!");
            }
            else {
                unlink $out; # Just tidying
            }
        }
    }

    return;
}

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::Tool::CheckMacros - LCFG software packaging tool

=head1 VERSION

    This documentation refers to LCFG::Build::Tool::CheckMacros version 0.9.30

=head1 SYNOPSIS

    my $tool = LCFG::Build::Tool::CheckMacros->new( dir => '.' );

    $tool->execute;

    my $tool2 = LCFG::Build::Tool::CheckMacros->new_with_options();

    $tool2->execute;

=head1 DESCRIPTION

This module provides software release tools for the LCFG build
suite.

The LCFG build tools have support for autoconf-style (e.g. @FOO@)
macro substitution when building packages. There is a set of macros
which are built-in and the list can be extended by the user. This is a
tool for checking substitution variable usage to help spot potential
problems. It prints out a list of warnings, ordered by importance,
along with the file names and line numbers of where the macros are
used.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

=head1 ATTRIBUTES

The following attributes are modifiable via the command-line (i.e. via
@ARGV) as well as the normal way when the Tool object is
created. Unless stated the options take strings as arguments and can
be used like C<--foo=bar>. Boolean options can be expressed as either
C<--foo> or C<--no-foo> to signify true and false values.

=over 4

=item fix_deprecated

A boolean value which indicates whether any deprecated macros that are
found in the files scanned should be automatically replaced with their
modern equivalents.

=item dryrun

A boolean value which indicates whether actions which permanently
alter the contents of files should be carried out. The default value
is false (0). When running in dry-run mode various you will typically
get extra output to the screen showing what would have been done.

=item quiet

A boolean value which indicates whether the actions should attempt to
be quieter. The default value is false (0).

=item dir

The path of the project directory which contains the software for
which you want to create a release. If this is not specified then a
default value of the current directory (.) will be used. This
directory must already contain the LCFG build metadata file (lcfg.yml)
for the software.

=back

The following methods are not modifiable by the command-line, they are
however directly modifiable via the Tool object if
necessary. Typically you will only need to query these attributes,
they are automatically created when you need them using values for
some of the other command-line attributes.

=over 4

=item spec

This is a reference to the current project metadata object, see
L<LCFG::Build::PkgSpec> for full details.

=item vcs

This is a reference to the current version-control object, see
L<LCFG::Build::VCS> for full details.

=back

=head1 SUBROUTINES/METHODS

=over 4

=item execute

This method should be called to check macro usage within a project. It
will check every file which matches the specifications in the
C<translate> list (specified in the metadata file). Also, if present,
it will check the template for the project specfile. See the
"EXPLANATION OF OUTPUT" section below for an outline of the messages
which might be generated.

=item fail($message)

Immediately fails (i.e. dies) and displays the message.

=item log($message)

Logs the message to the screen if the C<quiet> attribute has not been
specified. A message string is prefixed with 'LCFG: ' to help visually
separate it from other output.

=back

=head1 EXPLANATION OF OUTPUT

The possible warnings are listed in order of importance are:

=over 4

=item Use of unknown macro

=item Use of deprecated macro

=item Use of linux-only macro

=item Use of macosx-only macro

=item Use of compile-time-only macro

=back

Note that none of the warnings can be truly considered an error.  Even
a message about an unknown macro is fine B<if> you add the
specification for that variable to a local C<CMakeLists.txt> file for
that component. In general it has to be left up to the software author
to interpret the true importance of a particular warning

The special case in which all of these warnings (except that for
"deprecated macro") should be considered a fatal error is with the RPM
specfile. By design, locally defined macros and those which are
platform specific or compile-time only cannot be used in the specfile.


=head1 DEPENDENCIES

This module is L<Moose> powered and uses L<MooseX::App::Cmd> to handle
command-line options.

The following modules from the LCFG build tools suite are also
required: L<LCFG::Build::Tool>, L<LCFG::Build::PkgSpec>,
L<LCFG::Build::VCS> and VCS helper module for your preferred
version-control system.

=head1 SEE ALSO

L<LCFG::Build::Tools>, L<LCFG::Build::Skeleton>, lcfg-reltool(1)

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

Fedora12, Fedora13, ScientificLinux5, ScientificLinux6, MacOSX7

=head1 BUGS AND LIMITATIONS

There are no known bugs in this application. Please report any
problems to bugs@lcfg.org, feedback and patches are also always very
welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2008 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
