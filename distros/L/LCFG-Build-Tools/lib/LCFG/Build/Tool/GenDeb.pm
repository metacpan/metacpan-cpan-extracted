package LCFG::Build::Tool::GenDeb;    # -*-perl-*-
use strict;
use warnings;

# $Id: GenDeb.pm.in 36519 2019-06-21 09:27:03Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tool/CheckMacros.pm.in,v $
# $Revision: 36519 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Tool/GenDeb.pm.in $
# $Date: 2019-06-21 10:27:03 +0100 (Fri, 21 Jun 2019) $

use v5.10;

our $VERSION = '0.9.30';

use File::Copy::Recursive ();
use File::Spec ();
use File::Find::Rule ();
use LCFG::Build::Utils;
use Template v2.14;
use Try::Tiny;

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

override '_load_vcs_module' => sub {
    my ($self) = @_;

    my $vcs = super;
    $vcs->logname( $self->logname );

    return $vcs;
};

__PACKAGE__->meta->make_immutable;

sub abstract {
    return q{Generate debian package metadata};
}

sub execute {
    my ($self) = @_;

    my $dir  = $self->dir;
    my $spec = $self->spec;
    my $vcs  = $self->vcs;

    my %templates;
    my @tmpldirs = grep { -d $_ }
               map { File::Spec->catdir( $_, 'templates', 'debian' ) }
               LCFG::Build::Utils::datadirs();

    # ignore dotfiles and backup files

    for my $tmpldir (@tmpldirs) {
        my @files = File::Find::Rule->file()
                                    ->not( File::Find::Rule->name('*~'),
                                           File::Find::Rule->name('.*') )
                                    ->relative
                                    ->in($tmpldir);

        for my $entry (@files) {
            $templates{$entry} ||= File::Spec->catfile( $tmpldir, $entry );
        }
    }

    # Find any extra doc files which should be included in the package
    my @docs;

    for my $doc (qw/README TODO/) {
        my $docfile = File::Spec->catfile( $dir, $doc );
        if ( -f $docfile && -s _ ) {
            push @docs, $doc;
        }
    }

    # Generate a temporary directory. If the debian directory does not
    # already exist then this will be simply renamed, otherwise the
    # contents will be merged.

    my $tmpdir = File::Temp::tempdir( 
        'lcfgXXXXXX',
        DIR     => $dir,
        CLEANUP => 1,
    );

    # Does this look like a component?

    my $comp_file = File::Spec->catfile( $dir, $spec->name . '.cin' );
    my $is_component = -f $comp_file ? 1 : 0;

    my $comp_type = 'shell';
    if ( $is_component ) {
        try {
            my $fh = IO::File->new( $comp_file, 'r' )
                or die "Cannot open $comp_file: $!\n";
            my $first_line = $fh->getline
                or die "Failed to read $comp_file: $!\n";
            if ( $first_line =~ m{^\#\!.*perl}i ) {
                $comp_type = 'perl';
            }
        } catch {
            warn $_;
        };
    }

    # Is there a nagios helper module?

    my $nagios_file = File::Spec->catfile( $dir, 'nagios',
                                           $spec->name . '.pm' );

    # Need to try both forms of the filename

    my $has_nagios = -f $nagios_file  ? 1 : 0;
    if ( !$has_nagios ) {
        $nagios_file .= '.cin';
        $has_nagios = -f $nagios_file ? 1 : 0;
    }

    # Does there appear to be a Perl library?

    my $libdir = File::Spec->catdir( $dir, 'lib' );
    my $looks_like_perl_lib = 0;
    if ( -d $libdir ) {
        my @files = File::Find::Rule->file()->name(qr/\.pm(\.cin)?$/)->in($libdir);
        if ( scalar @files > 0 ) {
            $looks_like_perl_lib = 1;
        }
    }

    # Process all the templates

    my $tt = Template->new(
        {
            ABSOLUTE => 1,
        }
    ) or die $Template::ERROR . "\n";

    my $args = {
        spec => $spec,
        vcs  => $vcs,
        docs => \@docs,
        is_component        => $is_component,
        comp_type           => $comp_type,
        looks_like_perl_lib => $looks_like_perl_lib,
        has_nagios          => $has_nagios,
    };

    for my $key (sort keys %templates) {

        # Only need these files for components
        if ( $key =~ m/^COMP/ && !$is_component ) {
            next;
        }

        if ( $key =~ m/^COMP-nagios/ && ( !$is_component || !$has_nagios ) ) {
            next;
        }

        my $tmpl = $templates{$key};

        my $target = $key;

        # Need to translate 'COMP' separately as otherwise it could
        # potentially resolve to the wrong thing.

        my $deb_name = $spec->deb_name;
        $target =~ s/\bCOMP\b/$deb_name/g;

        $target =~ s/\b((?:LCFG|DEB)_[A-Z]+)\b/
                     LCFG::Build::Utils::translate_macro($spec,$1)/gxe;

        $self->log("Creating debian/$target metadata file");

        my $tmpfile = File::Spec->catfile( $tmpdir, $target );
        $tt->process( $tmpl, $args, $tmpfile )
            or die $tt->error() . "\n";

        if ( $key eq 'rules' ) {
            chmod oct('0755'), $tmpfile;
        }
    }

    my $debdir = File::Spec->catdir( $dir, 'debian' );
    if ( !-d $debdir ) {
        $self->log("Creating debian directory '$debdir'");
        if ( !$self->dryrun ) {
            rename $tmpdir, $debdir
                or $self->fail("Failed to rename temporary directory: $!");
            $vcs->run_cmd( 'add', $debdir );

            my $rules_file = File::Spec->catfile( $debdir, 'rules' );
            $vcs->run_cmd( 'propset', 'svn:executable', '1', $rules_file );
        }
    } else {
        $self->log("Updating debian directory '$debdir'");
        if ( !$self->dryrun ) {
            File::Copy::Recursive::dircopy( $tmpdir, $debdir )
                or $self->fail("Failed to update debian directory: $!");
        }
    }

    $self->log("Please review the debian directory for this project");

    return;
}

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::Tool::GenDeb - Generate debian package metadata for project

=head1 VERSION

This documentation refers to LCFG::Build::Tool::GenDeb version 0.9.30

=head1 SYNOPSIS

    my $tool = LCFG::Build::Tool::GenDeb->new( dir => '.' );

    $tool->execute;

    my $tool2 = LCFG::Build::Tool::GenDeb->new_with_options();

    $tool2->execute;

=head1 DESCRIPTION

This module provides software release tools for the LCFG build
suite.

This module can be used to generate the necessary metadata for
building a simple Debian package for a project. The generated files
are not expected to be perfect but rather are intended to be a good
starting point which will require at least minor modification in most
cases.

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

=item logname

The name of the changelog file for this software project (e.g. Changes
or ChangeLog). By default the value specified in the LCFG metadata
file will be used.

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
L<LCFG::Build::VCS> for full details.

=back

=head1 SUBROUTINES/METHODS

=over

=item execute

Generates the necessary metadata files for a Debian package in the
C<debian> sub-directory for the project.

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

    Copyright (C) 2018-2019 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
