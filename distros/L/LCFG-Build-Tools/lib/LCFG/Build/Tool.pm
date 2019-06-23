package LCFG::Build::Tool;    # -*-perl-*-
use strict;
use warnings;

# $Id: Tool.pm.in 35448 2019-01-18 15:01:53Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tool.pm.in,v $
# $Revision: 35448 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Tool.pm.in $
# $Date: 2019-01-18 15:01:53 +0000 (Fri, 18 Jan 2019) $

our $VERSION = '0.9.30';

use File::HomeDir v0.58;
use File::Spec;
use LCFG::Build::PkgSpec v0.2.6;
use UNIVERSAL::require;

my $VCS_STUB = 'LCFG::Build::VCS::';

use Moose;

extends 'MooseX::App::Cmd::Command';

has 'dryrun' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Simulate operation',
);

has 'quiet' => (
    traits        => ['Getopt'],
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    cmd_aliases   => 'q',
    documentation => 'Less output to the screen',
);

has 'dir' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    default       => q{.},
    documentation => 'Project working directory',
);

has 'resultsdir' => (
    is            => 'rw',
    isa           => 'Str',
    lazy          => 1,
    default       => sub { File::Spec->catdir( File::HomeDir->my_home(),
                                               'lcfgbuild' ) },
    documentation => 'Base directory for storing results',
);

has '_spec' => (
    accessor => 'spec',
    isa      => 'LCFG::Build::PkgSpec',
    lazy     => 1,
    builder  => '_load_pkgspec',
);

has '_vcs' => (
    accessor => 'vcs',
    does     => 'LCFG::Build::VCS',
    lazy     => 1,
    builder  => '_load_vcs_module',
);

__PACKAGE__->meta->make_immutable;

# A simple loader method for the required LCFG version control module.
# Where necessary this can be overloaded by implementing classes to
# handle more complex cases.

sub _load_vcs_module {
    my ($self) = @_;

    my $spec = $self->spec;

    my $vcstype;
    if ( defined $spec->vcs && defined $spec->get_vcsinfo('type') ) {
        $vcstype = $spec->get_vcsinfo('type');
    }
    else {
        warn "No version-control information in the LCFG metafile for this project.\n";

        # Attempt to detect the version-control system, otherwise fall
        # back to the "None" module. This is not very extensible but I
        # have not yet come up with a simple method to provide support
        # for any/all version-control systems.

        my @modules = ( 'SVN', 'CVS' );


        for my $module (@modules) {
          my $vcs = $VCS_STUB . $module;
          if ( $vcs->require && $vcs->auto_detect($self->dir) ) {
            $vcstype = $module;
            last;
          }
        }

        if ( !$vcstype ) {
            $vcstype = 'None';
        }

        warn "Auto-detected that the $vcstype module should be used.\n";
    }

    my $vcsmodule = $VCS_STUB . $vcstype;

    $vcsmodule->require or die $@;

    my $vcs = $vcsmodule->new(
        quiet   => $self->quiet,
        dryrun  => $self->dryrun,
        module  => $spec->fullname,
        workdir => $self->dir,
    );

    return $vcs;
}

# A simple loader method for the LCFG package specification metadata.
# Where necessary this can be overloaded by implementing classes to
# handle more complex cases, e.g. where the module was not already
# checked out of the revision control system.

sub _load_pkgspec {
    my ($self) = @_;

    # Find and load the package specification.

    my $metafile = File::Spec->catfile( $self->dir, 'lcfg.yml' );

    my $spec = LCFG::Build::PkgSpec->new_from_metafile($metafile);

    return $spec;
}

sub output_dir {
    my ($self) = @_;

    my $spec = $self->spec;

    my $module  = $spec->fullname;
    my $version = $spec->version;

    # This retains compatibility with the previous version scheme.  By
    # doing this we reuse the _dev build directory for each build
    # rather than creating (potentially) lots of new ones.

    my $dirname = join q{-}, $module, $version;
    $dirname =~ s/\.dev[0-9]+$/_dev/;

    my $outdir = File::Spec->catdir( $self->resultsdir, $dirname );

    return $outdir;
}

sub fail {
    my ( $self, $message ) = @_;

    die $message . "\n";
}

sub log {
    my ( $self, $message ) = @_;

    if ( !$self->quiet ) {
        print {*STDERR} 'LCFG: ' . $message . "\n";
    }

    return;
}

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::Tool - LCFG software packaging tool

=head1 VERSION

    This documentation refers to LCFG::Build::Tool version 0.9.30

=head1 SYNOPSIS

    This is an interface and cannot be instantiated directly.

=head1 DESCRIPTION

This module provides software release tools for the LCFG build
suite.

This class is an interface which must be implemented by any LCFG build
tool. It has a set of attributes which are relevant to all
implementing classes. Any class implementing this interface must
provide a run() method.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

=head1 ATTRIBUTES

The following attributes are modifiable via the command-line (i.e. via
@ARGV) as well as the normal way when the Tool object is
created. Unless stated the options take strings as arguments and can
be used like C<--foo=bar>. Boolean options can be expressed as either
C<--foo> or C<--no-foo> to signify true and false values.

=over

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

=item resultsdir

When a project is packaged for release the generated products (the
gzipped source tar file, various build metadata files and possibly
binary RPMS, etc) are stored into a directory named after the
combination of the full name of the project and the version
number. For example, a project named 'foo' with version '1.2.3' would
have an output directory of 'foo-1.2.3'. You should note that if the
C<base> attribute is specified in the metadata file (this is the case
for LCFG components) then that is also used. If the previous example
was an LCFG component it would have a directory named
'lcfg-foo-1.2.3'.

This attribute controls the parent directory into which that generated
directory will be placed. The default on a Unix system is
C<$HOME/lcfgbuild/> which will be created if it does not already
exist.

=back

The following methods are not modifiable by the command-line, they are
however directly modifiable via the Tool object if
necessary. Typically you will only need to query these attributes,
they are automatically created when you need them using values for
some of the other command-line attributes.

=over

=item spec

This is a reference to the current project metadata object, see
L<LCFG::Build::PkgSpec> for full details.

=item vcs

This is a reference to the current version-control object, see
L<LCFG::Build::VCS> and associated helper modules for full details.

=back

=head1 SUBROUTINES/METHODS

=over

=item run

Any class implementing this interface B<MUST> have a run() method.

=item fail($message)

Immediately fails (i.e. dies) and displays the message.

=item log($message)

Logs the message to the screen if the C<quiet> attribute has not been
specified. A message string is prefixed with 'LCFG: ' to help visually
separate it from other output.

=back

=head1 DEPENDENCIES

This module is L<Moose> powered and uses L<MooseX::App::Cmd> to handle
command-line options.

The following modules from the LCFG build tools suite are also
required: L<LCFG::Build::PkgSpec>, L<LCFG::Build::VCS> and VCS helper
module for your preferred version-control system.

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

    Copyright (C) 2008-2013 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
