package LCFG::Build::VCS::None;  # -*-perl-*-
use strict;
use warnings;

# $Id: None.pm.in 35424 2019-01-18 10:01:16Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-VCS/lib/LCFG/Build/VCS/None.pm.in,v $
# $Revision: 35424 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-VCS/LCFG_Build_VCS_0_3_9/lib/LCFG/Build/VCS/None.pm.in $
# $Date: 2019-01-18 10:01:16 +0000 (Fri, 18 Jan 2019) $

our $VERSION = '0.3.9';

use v5.10;

use File::Copy::Recursive v0.36 ();
use File::HomeDir v0.58 ();
use File::Path ();
use File::Spec ();
use IO::Dir ();

use Moose;
with 'LCFG::Build::VCS';

has 'tagdir' => (
    is            => 'rw',
    isa           => 'Str',
    lazy          => 1,
    default       => sub { File::Spec->catdir( File::HomeDir->my_home(),
                                               'lcfgbuild', 'tags' ) },
);

has '+id' => ( default => 'None' );

# This should give a speed-up in loading

__PACKAGE__->meta->make_immutable;

sub checkcommitted {
    return 1;
}

sub genchangelog {
    return;
}

sub run_cmd {
    return;
}

sub tagversion {
    my ( $self, $version ) = @_;

    my $module = $self->module;

    $self->update_changelog($version);

    my $tag = $self->gen_tag($version);
    my $tagdir = File::Spec->catdir( $self->tagdir, $module, $tag );

    if ( !$self->dryrun ) {
        if ( -d $tagdir ) {
            File::Path::rmtree($tagdir);
        }
        File::Copy::Recursive::dircopy( $self->workdir, $tagdir )
              or die "Could not tag $module at $version\n";
    }

    return;
}

sub export {
    my ( $self, $version, $builddir ) = @_;

    my $module = $self->module;

    my $tag = $self->gen_tag($version);
    my $storedir = File::Spec->catdir( $self->tagdir, $module, $tag );

    if ( !-d $storedir ) {
        die "Could not find stored tag for $version of $module in $storedir\n";
    }

    my $target = join q{-}, $module, $version;
    my $exportdir = File::Spec->catdir( $builddir, $target );

    if ( !$self->dryrun ) {
        if ( -d $exportdir ) {
            File::Path::rmtree($exportdir);
        }
        File::Copy::Recursive::dircopy( $storedir, $exportdir )
              or die "Could not copy $storedir to $exportdir\n";
    }

    return $exportdir;
}

sub export_devel {
    my ( $self, $version, $builddir ) = @_;

    my $module = $self->module;

    my $target = join q{-}, $module, $version;
    my $exportdir = File::Spec->catdir( $builddir, $target );

    if ( !$self->dryrun ) {
        if ( -d $exportdir ) {
            File::Path::rmtree($exportdir);
        }
        my $workdir = $self->workdir;
        File::Copy::Recursive::dircopy( $workdir, $exportdir )
              or die "Could not copy $workdir to $exportdir\n";
    }

    return $exportdir;

}

sub checkout_project {
    my ( $self, $version, $outdir ) = @_;

    my $module = $self->module;
    my $basedir = File::Spec->catdir( $self->tagdir, $module );

    if ( !-d $basedir ) {
        die "Could not find the tag directory for $module\n";
    }

    my $tag;
    if ( defined $version ) {
        $tag = $self->gen_tag($version);
    }
    else {
        tie my %dir, 'IO::Dir', $basedir;
        $tag = (sort grep { !m/^\./} keys %dir)[-1];
    }

    my $tagdir = File::Spec->catdir( $basedir, $tag );

    if ( !-d $tagdir ) {
         die "Could not find the tag $tag for $module\n";
    }

    if ( !defined $outdir ) {
        $outdir = $module;
    }

    if ( !$self->dryrun ) {
        File::Copy::Recursive::dircopy( $tagdir, $outdir )
              or die "Could not checkout $module tag $tag\n";
    }

    return;
}

sub import_project {
    my ( $self, $dir, $version, $message ) = @_;

    my $module = $self->module;

    my $tag = $self->gen_tag($version);

    my $tagdir = File::Spec->catdir( $self->tagdir, $module, $tag );

    if ( !$self->dryrun ) {
        if ( -d $tagdir ) {
            File::Path::rmtree($tagdir);
        }
        File::Copy::Recursive::dircopy( $dir, $tagdir )
              or die "Could not import $dir\n";
    }

    return;
}

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::VCS::None - LCFG build tools for filesystem based version-control

=head1 VERSION

    This documentation refers to LCFG::Build::VCS::None version 0.3.9

=head1 SYNOPSIS

    my $dir = ".";

    my $spec = LCFG::Build::PkgSpec->new_from_metafile("$dir/lcfg.yml");

    my $vcs = LCFG::Build::VCS::None->new( module  => $spec->fullname,
                                           workdir => $dir );

    $vcs->genchangelog();

    if ( $vcs->checkcommitted() ) {
      $vcs->tagversion();
    }

=head1 DESCRIPTION

This is part of a suite of tools designed to provide a standardised
interface to version-control systems so that the LCFG build tools can
deal with project version-control in a high-level abstract fashion.

This module implements the interface specified by
L<LCFG::Build::VCS>. It provides support for a really simple
filesystem-based version-control system. The working copy can be
"tagged" at a particular release with copies of the source tree being
made in a tag directory. Support is also provided for exporting these
tagged releases. The aim of this module is to provide the minimum
necessary to manage the release and build of LCFG packages without
requiring a true version-control system such as CVS.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

=head1 ATTRIBUTES

=over 4

=item module

The name of the software package in this repository. This is required
and there is no default value.

=item workdir

The directory in which the commands should be carried out. This is
required and if none is specified then it will default to '.', the
current working directory. This must be an absolute path but if you
pass in a relative path coercion will automatically occur based on the
current working directory.

=item tagdir

This is the directory into which exported 'tags' of the working copy
should be placed. If it is not specified then the directory above the
specified the working directory will be used. This should be an
absolute path, if a relative path is given it will be converted.

=item quiet

This is a boolean value which controls the quietness of the various
methods. By default it is false. This currently does not have much
effect on this module but it might in the future.

=item dryrun

This is a boolean value which controls whether the commands will
actually have a real effect or just print out what would be done. By
default it is false.

=item logname

The name of the logfile to which information should be directed when
doing version updates. This is also the name of the logfile to be used
if you utilise the automatic changelog generation option. The default
file name is 'ChangeLog'.

=back

=head1 SUBROUTINES/METHODS

=over 4

=item checkcommitted()

This is a no-op for simple filesystem-based version control as there
is no concept of changes to a file having been committed to a
repository.

=item genchangelog()

This is a no-op for simple filesystem-based version control as there
is no revision-control system log from which to generate the logfile.

=item tagversion($version)

This method is used to tag a set of files for a project at a
particular version. The source tree will be copied into a directory
named after the tag within the directory specified with the C<tagdir>
option. It will also update the changelog appropriately. Tags are
generated using the I<gen_tag()> method, see below for details.

=item gen_tag($version)

Tags are generated from the name and version details passed in by
replacing any hyphens or dots with underscores and joining the two
fields with an underscore. For example, lcfg-foo and 1.0.1 would
become lcfg_foo_1_0_1.

=item run_cmd(@args)

This is a no-op as the simple filesystem-based version control does
not require a separate binary to carry out commands.

=item export( $version, $builddir )

This will export a particular tagged version of the module. You need
to specify the target "build" directory into which the exported tree
will be put. The exported tree will be named like
"modulename-version". For example:

  my $vcs = LCFG::Build::VCS::None->new(module => "lcfg-foo");
  $vcs->export( "1.2.3", "/tmp" );

Would give you an exported tree of code for the lcfg-foo module tagged
as lcfg_foo_1_2_3 and it would be put into /tmp/lcfg-foo-1.2.3/

For the export method to be successful you must have already "tagged"
a release using the C<tagversion> method.

This method returns the name of the directory into which the tree was
exported.

=item export_devel( $version, $builddir )

This is similar to the export method. It takes the current working
tree for a module and exports it directly to another tree based in the
specified target "build" directory. For example:

  my $vcs = LCFG::Build::VCS::None->new(module => "lcfg-foo");
  $vcs->export_devel( "1.2.3_dev", "/tmp" );

Would give you an exported tree of code for the lcfg-foo module
directory and it would be put into /tmp/lcfg-foo-1.2.3_dev/

This method returns the name of the directory into which the tree was
exported.

=item logfile()

This is a convenience method which returns the full path to the
logfile based on the workdir and logname attributes.

=item checkout_project()

This is not currently supported. You probably want to use the
C<export> method instead.

=item import_project()

This is a no-op as there is no concept of "importing" a project into
the simple filesystem-based version control system.

=back

=head1 DEPENDENCIES

This module is L<Moose> powered and it depends on
L<LCFG::Build::VCS>. It also requires L<File::Copy::Recursive>

=head1 SEE ALSO

L<LCFG::Build::PkgSpec>, L<LCFG::Build::VCS::CVS>, L<LCFG::Build::Tools>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

FedoraCore5, FedoraCore6, ScientificLinux5

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
