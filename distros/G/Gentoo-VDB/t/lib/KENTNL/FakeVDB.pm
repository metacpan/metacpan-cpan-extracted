use 5.006;    # our
use strict;
use warnings;

package KENTNL::FakeVDB;

our $VERSION = '0.001000';

# ABSTRACT: Generate a Fake VDB Layout for testing

# AUTHORITY

use Test::Needs;

sub check_requires {
    test_needs 'Test::TempDir::Tiny', 'Path::Tiny';
}

sub _tempdir {
    require Test::TempDir::Tiny;
    goto &Test::TempDir::Tiny::tempdir;
}

sub _path {
    require Path::Tiny;
    goto &Path::Tiny::path;
}

our (@stubs) = qw(
  BUILD_TIME CATEGORY CBUILD CFLAGS CHOST CONTENTS COUNTER CXXFLAGS
  DEFINED_PHASES DEPEND DESCRIPTION EAPI environment.bz2 FEATURES HOMEPAGE
  INHERITED IUSE IUSE_EFFECTIVE KEYWORDS LDFLAGS LICENSE NEEDED NEEDED.ELF.2
  PDEPEND PF PKGUSE PROVIDES RDEPEND repository REQUIRES SIZE SLOT USE );

sub mkvdb {
    my $tempdir = _tempdir('FakeVDB');
    for my $dir ( @{ $_[0]->{dirs} || [] } ) {
        _path($tempdir)->child($dir)->mkpath;
    }
    for my $file ( keys %{ $_[0]->{files} || {} } ) {
        my $f = _path($tempdir)->child($file);
        $f->parent->mkpath;
        $f->spew_raw( $_[0]->{files}->{$file} );
    }
    for my $package ( @{ $_[0]->{packages} || [] } ) {
        my ( $CAT, $PNV ) = $package =~ qr{\A([^/]+)/([^/]+)\z};
        my $d = _path($tempdir)->child($package);
        $d->mkpath;
        for my $stub ( @stubs, $PNV . '.ebuild' ) {
            $d->child($stub)->touch;
        }
    }
    return $tempdir;
}

1;

