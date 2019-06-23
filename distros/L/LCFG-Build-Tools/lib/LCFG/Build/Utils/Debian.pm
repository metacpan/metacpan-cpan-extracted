package LCFG::Build::Utils::Debian; # -*- perl -*-
use strict;
use warnings;

# $Id: Debian.pm.in 35444 2019-01-18 11:42:09Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Tool/Pack.pm.in,v $
# $Revision: 35444 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Utils/Debian.pm.in $
# $Date: 2019-01-18 11:42:09 +0000 (Fri, 18 Jan 2019) $

our $VERSION = '0.9.30';

use v5.10;

use Digest;
use Fcntl qw(SEEK_SET);
use File::Copy ();
use File::Find ();
use File::Find::Rule ();
use File::pushd ();
use File::Spec ();
use File::Temp ();
use IPC::Run ();
use Template v2.14 ();
use LCFG::Build::Utils;
use LCFG::Build::VCS v0.3.7;
use Try::Tiny;

sub generate_metadata_post {
    my ( $self, $pkgspec, $srcdir, $resultsdir, $options ) = @_;
    $options //= {};

    if ( !defined $srcdir ) {
        $srcdir = q{.};
    }
    if ( !File::Spec->file_name_is_absolute( $srcdir ) ) {
        $srcdir = File::Spec->rel2abs( $srcdir );
    }

    if ( !defined $resultsdir ) {
        $resultsdir = q{.};
    }
    if ( !File::Spec->file_name_is_absolute( $resultsdir ) ) {
        $resultsdir = File::Spec->rel2abs( $resultsdir );
    }

    # Optionally generate the debian tar and DSC files

    my $debdir = File::Spec->catdir( $srcdir, 'debian' );

    if ( !-d $debdir ) {
        return;
    }

    # The changelog only changes in the repository when a release is
    # tagged. For devel builds we need to add an entry so that the
    # versions match.

    if ( $options->{devel_build} ) {
        my $logfile = File::Spec->catfile( $debdir, 'changelog' );

        LCFG::Build::VCS::update_debian_changelog( $logfile,
                    {
                        pkgname      => $pkgspec->deb_name,
                        version      => $pkgspec->deb_version,
                        distribution => 'UNRELEASED',
                    } );
    }

    my $tarname     = $pkgspec->tarname;
    my $deb_tarname = $pkgspec->deb_tarname;
    my $deb_dscname = $pkgspec->deb_dscname;
    my $deb_srctarname = $pkgspec->deb_srctarname;

    my $deb_tarfile;
    try {
        my $deb_srctarfile
            = File::Spec->catfile( $resultsdir, $deb_srctarname );
        symlink $tarname, $deb_srctarfile
            or die "Failed to symlink $tarname $deb_srctarfile";

        $deb_tarfile = generate_debtar( $deb_tarname, $srcdir, $resultsdir );
    } catch {
        warn "Failed to generate Debian tar file: $_\n";
        $deb_tarfile = undef;
    };

    if ( $deb_tarfile ) {
        say STDERR "LCFG: Debian Tar file is: $deb_tarfile";
    } else {
        return;
    }

    my $deb_dscfile;
    try {
        $deb_dscfile = generate_dsc( $deb_dscname, $deb_tarname,
                                     $deb_srctarname, $srcdir, $resultsdir );
    } catch {
        warn "Failed to generate Debian DSC file: $_\n";
        $deb_dscfile = undef;
    };

    if ( $deb_dscfile ) {
        say STDERR "LCFG: Debian DSC file is: $deb_dscfile";
    }

    return;
}

sub generate_dsc {
    my ( $dsc_name, $deb_tarname, $tarname, $srcdir, $resultsdir ) = @_;

    my $debdir = File::Spec->catdir( $srcdir, 'debian' );

    my $dsc_file = File::Spec->catfile( $resultsdir, $dsc_name );

    # Source format

    my $source_format;

    my $format_file = File::Spec->catfile( $debdir, 'source', 'format' );
    eval {
        my $fh = IO::File->new( $format_file, 'r' ) or die "$!\n";
        $source_format = $fh->getline or die "$!\n";
        chomp $source_format;
    };
    if ($@) {
        die "Failed to read debian/source/format: $@";
    }
        
    # Control file

    my $control_file = File::Spec->catfile( $debdir, 'control' );

    my $packages = parse_control($control_file);
    my %archs;
    for my $pkg (@{$packages}) {
        if ( $pkg->{architecture} ) {
            $archs{ $pkg->{architecture} } = 1;
        }
    }

    # Changelog

    my $version;
    my $changes_file = File::Spec->catfile( $debdir, 'changelog' );
    eval {
        my $fh = IO::File->new( $changes_file, 'r' ) or die "$!\n";
        my $first_line;
        while ( !$first_line || $first_line !~ m/\S/ ) {
            $first_line = $fh->getline or die "$!\n";
        }
        if ( $first_line =~ m/\(([^)]+)\)/ ) {
            $version = $1;
        } else {
            die "failed to parse '$first_line'\n";
        }
    };
    if ($@) {
        die "Failed to read debian/changelog: $@";
    }

    # Files

    my @files;
    for my $file ( $tarname, $deb_tarname ) {

        my $data = {
            name => $file,
        };

        my $path = File::Spec->catfile( $resultsdir, $file );

        my $fh = IO::File->new( $path, 'r' )
            or die "Could not read '$file': $!\n";

        $data->{size} = -s $path;

        for my $algo ( qw/MD5 SHA-1 SHA-256/ ) {
            my $digest = Digest->new($algo);

            $fh->seek( 0, SEEK_SET );
            $digest->addfile($fh);

            my $key = lc $algo;
            $key =~ s/\-//;
            $data->{$key} = $digest->hexdigest;
        }

        push @files, $data;
    }

    my $tmpfile = File::Temp->new(
        TEMPLATE => 'lcfgXXXXXX',
        SUFFIX   => '.dsc',
        DIR      => $resultsdir,
        UNLINK   => 0,
    );

    my @inc = grep { -d $_ }
              map { File::Spec->catdir( $_, 'templates' ) }
              LCFG::Build::Utils::datadirs();

    my $tt = Template->new(
        {
            INCLUDE_PATH => \@inc,
            POST_CHOMP   => 1,
            FILTERS => {
                pretty_case => sub { my $pretty = ucfirst lc $_[0];
                                     $pretty =~ s/-(.)/-\u$1/g;
                                     return $pretty; },
            },
        }
    ) or die $Template::ERROR . "\n";

    my $args = {
        source_format => $source_format,
        files         => \@files,
        packages      => $packages,
        archs         => [sort keys %archs],
        pkg_version   => $version,
    };

    $tt->process( 'dsc.tt', $args, $tmpfile )
        or die $tt->error() . "\n";

    rename $tmpfile->filename, $dsc_file or die "$!\n";

    return $dsc_file;
}

sub parse_control {
    my ($control_file) = @_;

    my $slot = 0;
    my $key;
    my @packages;

    my $fh = IO::File->new( $control_file, 'r' )
        or die "Failed to open '$control_file': $!\n";

    my $linenum = 0;
    while ( defined( my $line = $fh->getline ) ) {
        $linenum++;
        chomp $line;

        if ( $line =~ m/^\s*$/ ) {      # divider
            if ( defined $packages[$slot] ) {
                $slot++;
            }
        } else {
            if ( $line =~ m/^\s+/ ) {   # continuation
                if ( defined $packages[$slot] ) {
                    if ( $packages[$slot]->{$key} ) {
                        $packages[$slot]->{$key} .= "\n";
                    }
                    $packages[$slot]->{$key} .= $line;
                } else {
                    die "Invalid line $linenum of '$control_file': $line\n";
                }
            } elsif ( $line =~ m/^([^\s:]+):\s*(.+)/s ) {
                $packages[$slot] //= {};

                $key      = lc $1;
                my $value = $2 // q{};

                $packages[$slot]->{$key} = $value;
            } else {
                die "Invalid line $linenum of '$control_file': $line\n";
            }
        }
    }

    return \@packages;
}

sub generate_debtar {
    my ( $tarname, $srcdir, $resultsdir ) = @_;

    my $debdir = File::Spec->catdir( $srcdir, 'debian' );

    # Need to ensure we are in the source directory before adding
    # files to the tar archive.

    my $dh = File::pushd::pushd($srcdir);

    require Archive::Tar;
    require IO::Zlib;

    my $tar = Archive::Tar->new();

    $tar->setcwd($srcdir);

    File::Find::find(
        {
            wanted => sub {
                my $name = File::Spec->abs2rel( $File::Find::name, $srcdir );
                $tar->add_files($name);
            },
            no_chdir => 1,
        },
        $debdir
    );

    my $tarfile = File::Spec->catfile( $resultsdir, $tarname );

    $tar->write( $tarfile, 1 );

    return $tarfile;
}

sub build {
    my ( $self, $dir, $dscfile, $options ) = @_;
    $options //= {};

    my $builddir = File::pushd::tempd();

    my @unpack_cmd = ( 'dpkg-source', '--extract', $dscfile );

    my $unpack_out;
    my $unpack_ok = IPC::Run::run \@unpack_cmd, '>&', \$unpack_out;
    print STDERR $unpack_out;
    if ( !$unpack_ok ) {
        die "Failed to extract source\n";
    }

    my $source_dir;
    if ( $unpack_out =~ m/^dpkg-source:.+extracting\s+(\S+)\s+in\s+(\S+)/m ) {
        $source_dir = $2;

        my $dh = File::pushd::pushd($source_dir);
        my @build_cmd = ( 'debuild' );

        if ( $options->{sourceonly} ) {
            push @build_cmd, '-S';
        }
        if ( $options->{nodeps} ) {
            push @build_cmd, '--no-check-builddeps';
        }
        if ( !$options->{sign} ) {
            push @build_cmd, '--no-sign';
        }

        system @build_cmd;
    } else {
        die "Failed to locate source directory\n";
    }

    my @packages;
    my @files = File::Find::Rule->file()->maxdepth(1)->in($builddir);

    for my $file (sort @files) {
        my $basename = ( File::Spec->splitpath($file) )[2];
        my $target = File::Spec->catfile( $dir, $basename );
        File::Copy::move( $file, $target )
            or die "Could not move $file to $target: $!\n";

        if ( $basename =~ m/\.deb$/ ) {
            push @packages, $target;
        }
    }

    return {
        packages => \@packages,
        source   => $dscfile,
    };
}

1;
__END__
