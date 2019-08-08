# Copyright (c) 2019 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

*MY::postamble = \&File::ShareDir::Install::postamble;

install_share 'share';

my %versions = map {
    my $module = $_;
    my $file   = "lib/$module.pm";
    $file      =~ s{::}{/}g;
    $module => {
        file    => $file,
        version => MM->parse_version($file),
    }
} qw(
    Math::DifferenceSet::Planar
    Math::DifferenceSet::Planar::Data
    Math::DifferenceSet::Planar::Schema
    Math::DifferenceSet::Planar::Schema::Result::DifferenceSet
);

WriteMakefile(
    NAME                => 'Math::DifferenceSet::Planar',
    VERSION_FROM        => 'lib/Math/DifferenceSet/Planar.pm',
    PREREQ_PM           => {
        'Carp',         => 0,
        'DBD::SQLite'   => '1.48',
        'DBIx::Class'   => 0,
        'File::Share'   => 0,
        'File::Spec'    => 0,
        'Math::Prime::Util' => '0.59',
    },
    ABSTRACT_FROM       => 'lib/Math/DifferenceSet/Planar.pm',
    AUTHOR              => 'Martin Becker <becker-cpan-mp (at) cozap.com>',
    SIGN                => 1,
    LICENSE             => 'perl',
    META_MERGE          => {
        provides        => \%versions,
    },
    MIN_PERL_VERSION    => '5.010',
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker'       => '7.06',
        'File::ShareDir::Install'   => 0,
    },
    TEST_REQUIRES       => {
        'Test::More'    => 0,
    },
);
