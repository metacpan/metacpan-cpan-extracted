package LCFG::Build::Tool::Submit; # -*-perl-*-
use strict;
use warnings;

our $VERSION = '0.9.30';

use File::Find::Rule ();
use File::Spec ();
use Readonly;
Readonly my $PKGSUBMIT     => '/usr/sbin/pkgsubmit';
Readonly my $PKGSUBMIT_DIR => '/etc/pkgsubmit';

# $Id:$
# $Source:$
# $Revision:$
# $HeadURL:$
# $Date:$

use Moose;

extends 'LCFG::Build::Tool';

has 'bucket' => (
    traits    => ['Getopt'],
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    cmd_aliases   => 'B',
    documentation => 'The destination bucket for the RPMs',
);

has 'file' => (
    traits    => ['Getopt'],
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    default   => 'default.conf',
    cmd_aliases   => 'f',
    documentation => 'Alternative pkgsubmit configuration file to be used',
);

__PACKAGE__->meta->make_immutable;
no Moose;

sub abstract {
    return q{Submit previously built RPMs};
}

sub execute {
    my ($self) = @_;

    my $spec = $self->spec;

    my $version = $spec->version;
    my $module  = $spec->fullname;

    my $outdir = $self->output_dir;

    if ( !-d $outdir ) {
        $self->fail("Failed to find anything for $module-$version, do you need to build the packages?");
    }

    my $file = $self->file;
    if ( $file !~ m/\.conf$/ ) {
        $file .= '.conf';
    }

    my $config = File::Spec->catfile( $PKGSUBMIT_DIR, $file );

    if ( !-f $config ) {
        $self->fail("Could not find the $file pkgsubmit configuration");
    }

    my @rpms = sort 
        File::Find::Rule->file->name('*.rpm')->maxdepth(1)->in($outdir);

    my $count = scalar @rpms;
    if ( $count == 0 ) {
        $self->fail("Failed to find any RPMs for $module-$version, do you need to build the packages?");
    }

    my @cmd = ( $PKGSUBMIT, '-x', '-f', $file, '-B', $self->bucket, @rpms );

    if ( $self->dryrun ) {
        $self->log("Dry-Run: @cmd");
    }
    else {
        my $result = system @cmd;
        if ( $result == 0 ) {
            $self->log("Successfully submitted $count RPMs for $module-$version");
        } else {
            $self->fail("Failed to submit RPMs for $module-$version");
        }
    }

    return;
}

1;
__END__

=head1 NAME

LCFG::Build::Tool::Submit - Tool for submitting RPMs

=head1 VERSION

This documentation refers to LCFG::Build::Tool::Submit version 0.9.30

=head1 USAGE

    my $tool = LCFG::Build::Tool::Submit->new( dir => '.' );

    $tool->execute;

    my $tool2 = LCFG::Build::Tool::Submit->new_with_options();

    $tool2->execute;

=head1 DESCRIPTION

This module provides software release tools for the LCFG build suite.

This is a tool for submitting RPMs which have been built using the
LCFG build tools. It uses the pkgsubmit(8) command to do the actual
work of submission. It avoids the need to know where the build
products have been saved by the build tools, it also attempts to do
some sanity checking before running the pkgsubmit command. This tool
has been designed to work for the School of Informatics but it should
work anywhere which has pkgsubmit installed and correctly configured.

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

=item bucket

This is the name of the C<bucket> into which the package is
submitted. A bucket is a directory within an RPM repository into which
RPMs are stored. This is a required attribute and as such it must be
specified on the command line, there is no default value.

=item file

This is the name of the pkgsubmit configuration file to be used. If
none is specified then the C<default.conf> file is used.

=back

=head1 SUBROUTINES/METHODS

=over 4

=item execute

This method carries out the work of finding the RPMs and submitting
them to the desired location using pkgsubmit.

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

This application also requires L<File::Find::Rule> and L<Readonly>.

=head1 SEE ALSO

pkgsubmit(8), L<LCFG::Build::Tools>, lcfg-reltool(1)

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

Fedora12, Fedora13, ScientificLinux5, ScientificLinux6, MacOSX7

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
