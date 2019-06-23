package LCFG::Build::Tool::MicroVersion;    # -*-perl-*-
use strict;
use warnings;

# $Id: MicroVersion.pm.in 35202 2018-12-12 15:10:41Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tool/MicroVersion.pm.in,v $
# $Revision: 35202 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Tool/MicroVersion.pm.in $
# $Date: 2018-12-12 15:10:41 +0000 (Wed, 12 Dec 2018) $

our $VERSION = '0.9.30';

use Moose;

extends 'LCFG::Build::Tool';

# We do not want this option for these commands so use an override.

has '+resultsdir' => ( traits => ['NoGetopt'] );

has 'logname' => (
    is            => 'rw',
    isa           => 'Str',
    lazy          => 1,
    default       => sub { $_[0]->spec->get_vcsinfo('logname') || 'ChangeLog' },
    documentation => 'The VCS log file name',
);

has 'checkcommitted' => (
    is            => 'rw',
    isa           => 'Bool',
    lazy          => 1,
    default       => sub { $_[0]->spec->get_vcsinfo('checkcommitted') },
    documentation => 'Check for uncommitted changes',
);

has 'genchangelog' => (
    is            => 'rw',
    isa           => 'Bool',
    lazy          => 1,
    default       => sub { $_[0]->spec->get_vcsinfo('genchangelog') },
    documentation => 'Generate the change log from the VCS log',
);

has 'store_version' => (
    is            => 'rw',
    isa           => 'Bool',
    lazy          => 1,
    default       => sub { $_[0]->spec->get_vcsinfo('store_version') },
    documentation => 'Store the version string into a simple text file',
);
    
override '_load_vcs_module' => sub {
    my ($self) = @_;

    my $vcs = super;
    $vcs->logname( $self->logname );

    return $vcs;
};

__PACKAGE__->meta->make_immutable;

sub abstract {
    return q{Tag the source tree as a particular release};
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    return $self->release('micro');
}

sub release {
    my ( $self, $reltype ) = @_;

    $reltype ||= 'micro';

    my ( $spec, $vcs ) = ( $self->spec, $self->vcs );

    if ( $self->checkcommitted ) {
        my ( $ok, @files ) = $vcs->checkcommitted();
        if ( !$ok ) {
            warn "There are uncommitted files\n";
            if ( !$self->quiet ) {
                for my $file (@files) {
                    warn "\t" . $file . "\n";
                }
            }
            exit 1;
        }
    }

    if ( $self->genchangelog ) {
        $vcs->genchangelog();
    }

    if ( $reltype eq 'micro' ) {
        $spec->update_micro();
    }
    elsif ( $reltype eq 'minor' ) {
        $spec->update_minor();
    }
    elsif ( $reltype eq 'major' ) {
        $spec->update_major();
    }
    else {
        $self->fail("Unrecognised update type: $reltype");
    }

    if ( $self->dryrun ) {
        $self->log('Dry-run so not saving any changes to the metafile.');
    }
    else {
        $spec->save_metafile();
    }

    if ( $self->store_version ) {
        $vcs->store_version($spec->version);
    }

    my $debdir = File::Spec->catdir( $self->dir, 'debian' );
    if ( -d $debdir && !$self->dryrun ) {
        $self->log('Updating debian/changelog');
        $vcs->update_changelog( $spec->version, { style => 'debian' } );
    }

    $vcs->tagversion( $spec->version );

    return;
}

sub minorversion {
    my ($self) = @_;

    return $self->release('minor');
}

sub majorversion {
    my ($self) = @_;

    return $self->release('major');
}

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::Tool::MicroVersion - LCFG software packaging tool

=head1 VERSION

    This documentation refers to LCFG::Build::Tool::MicroVersion version 0.9.30

=head1 SYNOPSIS

    my $tool = LCFG::Build::Tool::MicroVersion->new( dir => '.' );

    $tool->execute;

    my $tool2 = LCFG::Build::Tool::MicroVersion->new_with_options();

    $tool2->execute;

=head1 DESCRIPTION

This module provides software release tools for the LCFG build
suite.

This tool will increment the smallest part of the project version
field and then tag a release of the project in the package
version-control repository.

It is possible to check that all changes to files have been committed
prior to doing a new release. Prior to actually doing the tagging it
is also possible to generate the project log file from the
version-control system logs.

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

=item logname

The name of the changelog file for this software project (e.g. Changes
or ChangeLog). By default the value specified in the LCFG metadata
file will be used.

=item checkcommitted

This is a boolean value which signifies whether the software project
should be checked for uncommitted files before a new release is
made. By default the value specified in the LCFG metadata file will be
used.

=item genchangelog

This is a boolean value which signifies whether the changelog file for
the software project should be generated from the commit logs of the
version-control system. By default the value specified in the LCFG
metadata file will be used.

=item store_version

This is a boolean value which controls whether the version string
(e.g. C<1.2.3>) should be stored into a F<lcfg-build-id.txt> file when
a new project version is tagged. By default the value specified in the
LCFG metadata file will be used.

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

=item execute()

This will increment the smallest part of the version field and then
uses the appropriate L<LCFG::Build::VCS> module to tag a new
release. This also resets the release field to one. See
L<LCFG::Build::PkgSpec> for full details regarding the version field.

It is possible to check that all changes to files have been committed
prior to doing a new release. If uncommitted changes are detected then
the tool will exit with a code of 1. If you have not asked the tool to
be quiet it will also print out the list of uncommitted files.

Prior to actually doing the tagging it is possible to generate the
project log file from the version-control system logs.

The C<tagversion> method of the appropriate L<LCFG::Build::VCS> module
will be used to actually tag the project source code at the new
version.

=item release($level)

This is the method which actually does the work. It takes one optional
parameter which specifies the level of the release, if it is not
specified then only the smallest (micro) part of the version field
will be incremented. When specifying the level it can be any of
'major', 'minor' or 'micro'. When the smallest part of the version
field is incremented the release field is also reset to one. For
details of the procedure for updating the other parts of the version
field see below.

=item minorversion()

This is a convenience method which calls the release() method with the
level parameter set to 'minor'. As well as incrementing the middle
part of the version field the smallest part will be reset to zero and
the release field will be reset to one.

=item majorversion()

This is a convenience method which calls the release() method with the
level parameter set to 'major'. As well as incrementing the largest
part of the version field the middle and smallest parts will be reset
to zero and the release field will be reset to one.

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
