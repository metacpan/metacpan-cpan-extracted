package LCFG::Build::Utils::RPM;    # -*-perl-*-
use strict;
use warnings;

# $Id: RPM.pm.in 35173 2018-12-07 16:25:33Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Utils/RPM.pm.in,v $
# $Revision: 35173 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Utils/RPM.pm.in $
# $Date: 2018-12-07 16:25:33 +0000 (Fri, 07 Dec 2018) $

our $VERSION = '0.9.30';

use DateTime   ();
use English qw(-no_match_vars);
use File::Copy ();
use File::Find::Rule ();
use File::Spec ();
use File::Temp ();
use IO::File ();
use Text::Wrap ();

use LCFG::Build::Utils;

sub generate_metadata {
    my ( $self, $pkgspec, $dir, $outdir ) = @_;

    $outdir ||= q{.};
    $dir    ||= q{.};

    my $specfile = join q{.}, $pkgspec->fullname, 'spec';
    $specfile = File::Spec->catfile( $dir, $specfile );

    if ( !-f $specfile ) {
        $specfile = File::Spec->catfile( $dir, 'specfile' );
        if ( !-f $specfile ) {
            die "You need to generate a specfile\n";
        }
    }

    # Do our best to find a changelog file of some description.

    my $logfile = $pkgspec->get_vcsinfo('logname');
    if ( !defined $logfile ) {
        for my $file (qw/ChangeLog Changes/) {
            my $path = File::Spec->catfile( $dir, $file );
            if ( -f $path ) {
                $logfile = $file;
                last;
            }
        }
    }

    my $extra = {};
    if ( defined $logfile ) {
        $logfile = File::Spec->catfile( $dir, $logfile );
        if ( -f $logfile ) {

            my $changelog = format_changelog($logfile);
            $extra->{LCFG_CHANGELOG} = $changelog;
        }
    }

    my $specname = $pkgspec->rpmspec_name;
    my $output   = File::Spec->catfile( $outdir, $specname );

    LCFG::Build::Utils::translate_file( $pkgspec, $specfile,
                                        $output,
                                        $extra );

    # Do this so the generated tar-file contains a usable specfile

    File::Copy::copy( $output, $specfile );

    return;
}

sub format_changelog {
  my ($file) = @_;

  my @entries = parse_changelog($file);

  if ( scalar @entries == 0 ) {
    my $dt = DateTime->now();
    my $entry = {
      year  => $dt->year,
      month => $dt->month,
      day   => $dt->day,
    };
    return format_entry($entry);
  }

  my $changelog = q{};
  for my $entry (@entries) {
    $changelog .= format_entry($entry);
  }

  return $changelog;
}

sub format_entry {
  my ($entry) = @_;

  my $dt = eval { DateTime->new( year  => $entry->{year},
                                 month => $entry->{month},
                                 day   => $entry->{day} ) };

  if ( $EVAL_ERROR || !defined $dt ) {
    return q{};
  }

  my $formatted_date = $dt->strftime('%a %b %d %Y');

  my $title = $entry->{title};
  if ( !defined $title ) {
    $title = $ENV{EMAIL} || getpwuid $UID;
  }

  if ( $title =~ /\s*cvs:\s*new release/i && defined $entry->{release} ) {
    $title = "<<<< Release: $entry->{release} >>>>";
  }

  my $output = q{* } . $formatted_date . q{ } . $title . "\n";

  my @body;
  if ( defined $entry->{body} ) {
    @body = @{$entry->{body}};
  }

  if ( scalar @body == 0 ) {
    push @body, 'No release information available';
  }

  for my $item (@body) {
    $output .= Text::Wrap::wrap( '- ', '  ', $item ) . "\n";
  }

  $output .= "\n";

  return $output;
}

sub parse_changelog {
  my ($file) = @_;

  my @data;
  if ( !-f $file || -z $file ) {
    return @data;
  }

  my $fh = IO::File->new( $file, 'r' )
    or die "Could not open file '$file': $OS_ERROR\n";

  my $current;
  while ( defined( my $line = <$fh> ) ) {
    chomp $line;

    if ( $line =~ m/^\s*$/ ) {
      next;
    } elsif ( $line =~ m/^(\d+)-(\d+)-(\d+)\s*(.*)$/ ) {
      $current = $data[$#data + 1] = { year  => $1,
                                       month => $2,
                                       day   => $3,
                                       title => $4,
                                       body  => [] };
    } else {
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;

      my $body = $current->{body};
      if ( $line =~ m/^\*\s*(.+)/ ) {
        my $entry = $1;
        if ( $entry =~ m/^release:\s*(.+)$/i ) {
          $current->{release} = $1;
        }

        push @{$body}, $entry;
      } elsif ( scalar @{$body} == 0 ) {
        push @{$body}, $line;
      } else {
        ${$body}[$#{$body}] .= " $line";
      }
    }

  }

  return @data;
}

sub build {
    my ( $self, $dir, $specfile, $options ) = @_;

    if ( !defined $options ) {
        $options = {};
    }

    my @args;
    if ( $options->{sourceonly} ) {
        @args = ( '-bs', '--nodeps' );
    } else {
        @args = ( '-ba' );
        if ( $options->{nodeps} ) {
            push @args, '--nodeps';
        }
    }
    if ( $options->{sign} ) {
        push @args, '--sign';
    }

    my $tempdir = File::Temp::tempdir( 'buildtools-XXXXX',
                                       TMPDIR  => 1,
                                       CLEANUP => 1 );

    my $builddir;
    if ( $options->{builddir} ) {
      $builddir = $options->{builddir};
    } else {
      $builddir = File::Spec->catdir( $tempdir, 'BUILD' );
    }

    if ( !-d $builddir ) {
      mkdir $builddir or die "Could not create directory $builddir: $!\n";
    }

    my $rpmdir = File::Spec->catdir( $tempdir, 'RPMS' );
    mkdir $rpmdir or die "Could not create directory $rpmdir: $!\n";

    my $buildroot = File::Spec->catdir( $tempdir, 'BUILDROOT' );

    my @cmd = ( '/usr/bin/rpmbuild', @args,
                '--define', "_topdir $dir",
                '--define', "_builddir $builddir",
                '--define', "_specdir $dir",
                '--define', "_sourcedir $dir",
                '--define', "_srcrpmdir $dir",
                '--define', "_rpmdir $rpmdir",
                '--define', "_buildrootdir $buildroot",
                $specfile );

    my $ok = system @cmd;

    if ( $ok != 0 ) {
        die "Failed to build $specfile\n";
    }

    my ($source) =
      File::Find::Rule->file()->name('*.src.rpm')->maxdepth(1)->in($dir);

    my @packages;
    if ( !$options->{sourceonly} ) {
        my @rpms = File::Find::Rule->file()->name('*.rpm')->in($rpmdir);

        for my $rpm (sort @rpms) {
            my $basename = ( File::Spec->splitpath($rpm) )[2];
            my $target = File::Spec->catfile( $dir, $basename );
            File::Copy::move( $rpm, $target )
                or die "Could not move $rpm to $target: $!\n";

            push @packages, $target;
        }
    }

    return {
        packages => \@packages,
        source   => $source,
    };
}

1;
__END__

=head1 NAME

    LCFG::Build::Utils::RPM - LCFG software building utilities

=head1 VERSION

    This documentation refers to LCFG::Build::Utils::RPM version 0.9.30

=head1 SYNOPSIS

    my $dir = q{.};

    my $spec = LCFG::Build::PkgSpec->new_from_metafile("$dir/lcfg.yml");

    my $resultsdir = '/tmp/foo';
    LCFG::Build::Utils::RPM->generate_metadata( $spec, $dir, $resultsdir )

=head1 DESCRIPTION

This module provides a suite of utilities to help in building RPM
packages from LCFG projects, particularly LCFG components. The methods
are mostly used by tools which implement the LCFG::Build::Tool base
class (e.g. LCFG::Build::Tool::RPM) but typically they are designed to
be generic enough to be used elsewhere.

=head1 SUBROUTINES/METHODS

There are two public methods you can call on this class.

=over 4

=item generate_metadata( $pkgspec, $dir, $outdir )

This generates the necessary metadata file (i.e. the specfile) for
building RPM packages from this project.  It takes an LCFG build
package metadata object, an input directory where the template RPM
specfile and change log files are stored and an output directory where
the generate file should be placed.

=item build( $dir, $specfile, $options )

This actually builds the RPM packages using the C<rpmbuild>
command. It requires the name of the directory which contains the
source tar file and the RPM specfile. A reference to a hash of options
can be passed in, this allows one to specify things like only building
the source package (with "sourceonly") and making rpmbuild ignore
dependencies with "nodeps".

=back

=head1 DEPENDENCIES

For formatting the change log file you will need DateTime(3).

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
