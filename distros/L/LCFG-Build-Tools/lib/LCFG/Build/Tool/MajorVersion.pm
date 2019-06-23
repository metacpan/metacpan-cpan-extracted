package LCFG::Build::Tool::MajorVersion;    # -*-perl-*-
use strict;
use warnings;

# $Id: MajorVersion.pm.in 33768 2017-11-20 15:51:27Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tool/MajorVersion.pm.in,v $
# $Revision: 33768 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Tool/MajorVersion.pm.in $
# $Date: 2017-11-20 15:51:27 +0000 (Mon, 20 Nov 2017) $

our $VERSION = '0.9.30';

use Moose;

extends 'LCFG::Build::Tool::MicroVersion';

override 'abstract' => sub {
    return q{Tag the source tree as a particular major release};
};

override 'execute' => sub {
    my ($self) = @_;

    return $self->majorversion;
};

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::Tool::MajorVersion - LCFG software packaging tool

=head1 VERSION

    This documentation refers to LCFG::Build::Tool::MajorVersion version 0.9.30

=head1 SYNOPSIS

    my $tool = LCFG::Build::Tool::MajorVersion->new( dir => '.' );

    $tool->execute;

    my $tool2 = LCFG::Build::Tool::MajorVersion->new_with_options();

    $tool2->execute;

=head1 DESCRIPTION

This module provides software release tools for the LCFG build
suite.

This tool will increment the largest part of the project version
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

=item execute

This calls the C<majorversion> method of
L<LCFG::Build::Tool::MicroVersion>, you should read the documentation in
that module for more details of the procedures.

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
required: L<LCFG::Build::Tool::MicroVersion>, L<LCFG::Build::PkgSpec>,
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
