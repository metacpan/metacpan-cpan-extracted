package LCFG::Build::Utils::OSXPkg;    # -*-perl-*-
use strict;
use warnings;

# $Id: OSXPkg.pm.in 29224 2015-11-12 10:11:34Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Utils/MacOSX.pm.in,v $
# $Revision: 29224 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Utils/OSXPkg.pm.in $
# $Date: 2015-11-12 10:11:34 +0000 (Thu, 12 Nov 2015) $

our $VERSION = '0.9.30';

use File::Copy ();
use File::Spec ();
use File::Temp ();
use LCFG::Build::Utils;
use Sys::Hostname ();
use Readonly;

Readonly my $CMAKE => 'cmake';
Readonly my $MAKE => 'make';
Readonly my $PKGBUILD => 'pkgbuild';

sub build {
  my ( $self, $outdir, $tarfile, $dirname,
       $pkgname, $pkgversion, $pkgident,
       $filters, $scriptdir, $nopayload ) = @_;

  my $tempdir = File::Temp::tempdir( 'buildtools-XXXXX',
				     TMPDIR  => 1,
				     CLEANUP => 1 );
  chdir $tempdir;

  require Archive::Tar;
  require IO::Zlib;

  my $tar = Archive::Tar->new();
  my $tar_ok = $tar->extract_archive( $tarfile, 1);
  if ( !$tar_ok ) {
    die "Failed to extract '$tarfile': " . $tar->error . "\n";
  }

  my $prev_dir = Cwd::getcwd(); # will need to go back to this later

  chdir $dirname or
    die "Failed to change directory into $dirname - check tar file.";

  my @cmake_cmd = ( $CMAKE, '.');
  my $cmake_ok = system @cmake_cmd;
  if ( $cmake_ok != 0 ) {
    die "Failed to run cmake.\n";
  }

  my $builddir = File::Temp::tempdir( 'buildtools-XXXXX',
				      TMPDIR  => 1,
				      CLEANUP => 1 );

  my $filename = File::Spec->catfile( $outdir, $pkgname . '.pkg') ;

  my @make_cmd = ( $MAKE, 'install',
		   'DESTDIR=' . $builddir);
  my $make_ok = system @make_cmd;
  if ( $make_ok != 0 ) {
    die "Failed to build project .\n";
  }

  my @pkgbuild_cmd = ( $PKGBUILD,
		       '--identifier' => $pkgident,
		       '--version'    => $pkgversion );

  # If there's no payload, don't specify the files to package
  if ( $nopayload ) {
    push @pkgbuild_cmd, '--nopayload';
  } else {
    push @pkgbuild_cmd, '--root' => $builddir;
  }

  # pkgbuild by default filters .DS_Store, CVS and .svn, but doesn't
  # if we use the --filter option, so add these explicitly
  my @default_filters = ( qw/ \.DS_Store CVS \.svn / );

  # Add a command line option for each filter
  foreach my $filter ( @default_filters, @$filters ) {
    push @pkgbuild_cmd, '--filter' => $filter;
  }

  if ( ( defined $scriptdir ) && ( -d $scriptdir ) ) {
    push  @pkgbuild_cmd, '--scripts' => $scriptdir;
  }
  push @pkgbuild_cmd, $filename;

  my $pkgbuild_ok = system @pkgbuild_cmd;
  if ( $pkgbuild_ok != 0 ) {
    die "Failed to make package.\n";
  }

  # Check there really is a package
  if ( ! -f $filename ) {
    die "Cannot find expected package: '$filename'.\n";
  }

  chdir $prev_dir;

  my @packages = ( $filename );
  return {
	  packages => \@packages
	 };
}

1;
__END__

=head1 NAME

    LCFG::Build::Utils::OSXPkg - LCFG software building utilities

=head1 VERSION

    This documentation refers to LCFG::Build::Utils::OSXPkg version 0.9.30

=head1 DESCRIPTION

This module provides a suite of utilities to help in building MacOSX
packages from LCFG projects, particularly LCFG components. The methods
are mostly used by tools which implement the LCFG::Build::Tool base
class (e.g. LCFG::Build::Tool::OSXPkg) but typically they are designed to
be generic enough to be used elsewhere.

=head1 SUBROUTINES/METHODS

There is one public method you can call on this class.

=over 4

=item build( $outdir, $tarfile, $dirname, $pkgname, $pkgversion, $pkgident, $filters, $scriptdir, $nopayload )

This method assumes that C<$tarfile> contains sources that C<cmake>
can build and install.  C<pkgbuild> is then called to create the
package.

=over 4

=item B<$outdir>

Absolute path to the directory where the package will be created.

=item B<$tarfile>

Absolute path to the tarfile to unpack, build and package.

=item B<$pkgname>

The full name of the package you want to generate,
e.g. C<lcfg-foo-1.2.3-4>.  C<.pkg> will be appended to this for you.

=item B<$pkgversion>

The version of the package, e.g. C<1.2.3.4>.

=item B<$pkgident>

A package identifier to pass to C<pkgbuild>, e.g. C<org.lcfg>.

=item B<$filters>

A reference to an array of filter expressions to pass to C<pkgbuild>.

=item B<$scriptdir>

Absolute path to a directory of scripts to pass to C<pkgbuild>.  There
is no filtering of the files in this directory and C<pkgbuild> will
copy all its contents into the package.

=item B<$nopayload>

A boolean that flags whether the package should be created with or
without a payload.

=back

=back

=head1 DEPENDENCIES

For building packages you will need CMake and pkgbuild.

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

Mac OS X 10.7

=head1 BUGS AND LIMITATIONS

There are no known bugs in this application. Please report any
problems to bugs@lcfg.org, feedback and patches are also always very
welcome.

=head1 AUTHOR

    Kenneth MacDonald <Kenneth.MacDonald@ed.ac.uk>
    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2008-2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
