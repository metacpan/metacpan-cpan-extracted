package LCFG::Build::Tools;    # -*-perl-*-
use strict;
use warnings;

# $Id: Tools.pm.in 35212 2019-01-03 10:09:17Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tools.pm.in,v $
# $Revision: 35212 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Tools.pm.in $
# $Date: 2019-01-03 10:09:17 +0000 (Thu, 03 Jan 2019) $

our $VERSION = '0.9.30';

use Moose;

extends qw(MooseX::App::Cmd);

use constant plugin_search_path => 'LCFG::Build::Tool';
use constant allow_any_unambiguous_abbrev => 1;

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__

=head1 NAME

    LCFG::Build::Tools - LCFG software release tools

=head1 VERSION

This documentation refers to LCFG::Build::Tools version 0.9.30

=head1 DESCRIPTION

LCFG::Build::Tools is a suite of tools designed to handle the
releasing of LCFG software projects and the creation of
packages. Support is available for developing projects within a
version-control systems (currently either CVS or None). By default a
source tar file is generated along with a specfile for building binary
RPMs. Support is provided for building binary RPMs directly. Work is
under way to also fully support the generation of MacOSX packages.

Although this software is designed for managing LCFG projects there is
nothing that requires the software be for LCFG. All the tools included
are designed to more widely applicable.

This suite has been intentionally designed to be easy to extend to
support new version-control systems (e.g. subversion, git, etc) and
new package formats (e.g. for Debian). It has also been designed to
ensure that it is easy to extend with additional command modules. For
further details see the online documentation at
http://www.lcfg.org/doc/buildtools/

=head1 COMMAND MODULES

This is a list of the LCFG build tool modules in this suite. You
should see the separate perl documentation for information on how to
use the modules.

=over

=item L<LCFG::Build::Utils>

Generic utilities for building packages.

=item L<LCFG::Build::Utils::RPM>

Utilities for building RPM packages.

=item L<LCFG::Build::Utils::MacOSX>

Utilities for building MacOSX packages.

=item L<LCFG::Build::Tool>

Build tool base class, only tool developers need to care about this.

=item L<LCFG::Build::Tool::CheckMacros>

Tool for checking the macro usage in your project.

=item L<LCFG::Build::Tool::MicroVersion>

Tool for tagging source code as a particular (micro-version) release.

=item L<LCFG::Build::Tool::MinorVersion>

Tool for tagging source code as a particular minor-version release.

=item L<LCFG::Build::Tool::MajorVersion>

Tool for tagging source code as a particular major-version release.

=item L<LCFG::Build::Tool::Pack>

Tool for packaging tagged source code into a tar file.

=item L<LCFG::Build::Tool::DevPack>

Tool for packaging tagged development code into a tar file.

=item L<LCFG::Build::Tool::RPM>

Tool for packaging tagged source code into a tar file and generating RPMs

=item L<LCFG::Build::Tool::SRPM>

Tool for packaging tagged source code into a tar file and generating an SRPM

=item L<LCFG::Build::Tool::DevRPM>

Tool for packaging tagged development code into a tar file and generating RPMs.

=item L<LCFG::Build::Tool::OSXPkg>

Tool for packaging tagged source code into a tar file and generating
packages for MacOSX

=item L<LCFG::Build::Tool::DevOSXPkg>

Tool for packaging tagged development code into a tar file and
generating packages for MacOSX

=back

=head1 CONFIGURATION AND ENVIRONMENT

Some of the tools use template files, by default it is assumed that
the standard template directory is
C</usr/local/share/lcfgbuild/templates> on MacOSX and
C</usr/share/lcfgbuild/templates> on all other platforms.
You can override this using the C<LCFG_BUILD_TMPLDIR> environment
variable. If you have done a local (i.e. non-root) install of this
module then this will almost certainly be necessary.

=head1 EXIT STATUS

After successfully running a command it will exit with code zero. An
error will result in a non-zero error code.

=head1 DEPENDENCIES

The LCFG build tools are L<Moose> powered and the L<MooseX::App::Cmd>
module is used to handle the command-line interface.

This module is part of the LCFG build tools suite and as such requires
L<LCFG::Build::Pkgspec> and L<LCFG::Build::VCS>.

The templates are processed using the perl Template Toolkit.

For building RPM packages you will need C<rpmbuild>.

You will also need L<Archive::Tar>, L<DateTime>, L<File::Find::Rule>,
L<IO::Zlib>, L<Text::Abbreviate>, L<UNIVERSAL::require> and
L<YAML::Syck>.

=head1 SEE ALSO

L<LCFG::Build::Skeleton>, lcfg-reltool(1)

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

    Copyright (C) 2008-2019 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
