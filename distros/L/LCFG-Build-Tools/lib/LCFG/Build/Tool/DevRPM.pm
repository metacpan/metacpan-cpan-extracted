package LCFG::Build::Tool::DevRPM;    # -*-perl-*-
use strict;
use warnings;

# $Id: DevRPM.pm.in 35383 2019-01-16 16:21:24Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tool/DevRPM.pm.in,v $
# $Revision: 35383 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Tool/DevRPM.pm.in $
# $Date: 2019-01-16 16:21:24 +0000 (Wed, 16 Jan 2019) $

our $VERSION = '0.9.30';

use v5.10;

use LCFG::Build::Utils::RPM;
use File::Basename ();
use File::Copy     ();
use File::Spec     ();

use Moose;

extends 'LCFG::Build::Tool::DevPack';

has 'sourceonly' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Only build source package',
);

has 'deps' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 1,
    documentation => 'Build dependency checking',
);

has 'sign' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Embed a GPG signature in the package',
);

override 'abstract' => sub {
    return q{Build binary RPMS from the development source tree};
};

override 'execute' => sub {
    my ($self) = @_;

    super;

    my %opts;
    if ( !$self->deps ) {
        $opts{nodeps} = 1;
    }
    if ( $self->sourceonly ) {
        $opts{sourceonly} = 1;
    }
    if ( $self->sign ) {
        $opts{sign} = 1;
    }

    my $spec = $self->spec;

    my $module  = $spec->fullname;

    my $outdir = $self->output_dir;

    # For 'devel' packages it can be useful to keep the build
    # directory to make it easier to inspect the build products.

    $opts{builddir} = $outdir;

    my $tarname = $spec->tarname;
    my $tarfile = File::Spec->catfile( $outdir, $tarname );

    my $specname = $spec->rpmspec_name;
    my $specfile = File::Spec->catfile( $outdir, $specname );

    my $result = LCFG::Build::Utils::RPM->build( $outdir, $specfile, \%opts );

    $self->log("Successfully built source package for $module");

    my $source_path = $result->{source};
    $self->log("Source: $source_path");

    if ( !$self->sourceonly ) {
        $self->log("Successfully built packages for $module");

        for my $package ( @{ $result->{packages} } ) {
            $self->log("Package: $package");
        }
    }

    return;
};

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::Tool::DevRPM - LCFG software packaging tool

=head1 VERSION

    This documentation refers to LCFG::Build::Tool::DevRPM version 0.9.30

=head1 SYNOPSIS

    my $tool = LCFG::Build::Tool::DevRPM->new( dir => '.' );

    $tool->execute;

    my $tool2 = LCFG::Build::Tool::DevRPM->new_with_options();

    $tool2->execute;

=head1 DESCRIPTION

This module provides software release tools for the LCFG build
suite.

This is a tool to take a development tree (working copy) of the source
for a project managed with the LCFG build tools and package it into a
gzipped source tar file. Build metadata files for supported platforms
(e.g. a specfile for building binary RPMs) are also generated at the
same time. It is also possible to do limited autoconf-style macro
substitution prior to the source being packaged. This allows the
generation of 'pristine' tar files where downstream users will be
unaware of the additional source-file processing that has been carried
out prior to distribution. Binary RPM packages will then be generated
from the gzipped source tar file using the generated specfile.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

=head1 ATTRIBUTES

The following attributes are modifiable via the command-line (i.e. via
@ARGV) as well as the normal way when the Tool object is
created. Unless stated the options take strings as arguments and can
be used like C<--foo=bar>. Boolean options can be expressed as either
C<--foo> or C<--no-foo> to signify true and false values.

=over 4

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

=item gencmake

This is a boolean value which controls whether CMake build files will
be created when the source code for the project is packaged. The
default is to take the setting from C<gencmake> option in the
C<buildinfo> section of the LCFG build metadata file.

=item translate

This is a boolean value which controls whether source files will be
translated BEFORE they are packaged. The default is to take the
setting from C<translate_before_pack> option in the C<buildinfo>
section of the LCFG build metadata file.

=item remove_after_translate

This is a boolean value which controls whether input files will be
removed after they have been translated. They are only removed if the
input and output filenames do not match (e.g. foo.cin becomes
foo). The default is to take the setting from
C<remove_input_after_translate> option in the C<buildinfo> section of
the LCFG build metadata file.

=item sourceonly

This is a boolean value which controls whether the binary packages
should be built as well as the source RPM.

=item sign

This is a boolean value which controls whether C<rpmbuild> should
embed a GPG signature in the package.

=item deps

This is a boolean value which controls whether C<rpmbuild> checks the
dependencies specified in the RPM specfile when it builds the source
or binary RPMs.

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

This method first calls the execute() method in
L<LCFG::Build::Tool::DevPack> to generate a gzipped source tar file
and the build metadata files for the various supported platforms
(e.g. a specfile for creating binary RPMs). Once that is done
C<rpmbuild> is used to create binary RPMs from the generated source
tar file and specfile.

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
required: L<LCFG::Build::Tool::DevPack>, L<LCFG::Build::PkgSpec>,
L<LCFG::Build::VCS> and VCS helper module for your preferred
version-control system.

For building RPMs you will also need L<LCFG::Build::Utils::RPM>.

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
