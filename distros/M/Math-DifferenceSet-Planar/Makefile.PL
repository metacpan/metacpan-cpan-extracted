# Copyright (c) 2019-2023 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

use strict;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;
use File::Spec;

*MY::postamble = \&File::ShareDir::Install::postamble;

install_share 'share';

my $DN = 'Math-DifferenceSet-Planar';
my %versions = map {
    my $module = $_;
    my @path   = ('lib', split /::/, "$module.pm");
    my $file   = join '/', @path;
    my $osfile = File::Spec->catfile(@path);
    $module => {
        file    => $file,
        version => MM->parse_version($osfile),
    }
} qw(
    Math::DifferenceSet::Planar
    Math::DifferenceSet::Planar::Data
    Math::DifferenceSet::Planar::Schema
    Math::DifferenceSet::Planar::Schema::Result::DatabaseVersion
    Math::DifferenceSet::Planar::Schema::Result::DifferenceSet
    Math::DifferenceSet::Planar::Schema::Result::DifferenceSetSpace
);

WriteMakefile(
    NAME                => 'Math::DifferenceSet::Planar',
    VERSION_FROM        => 'lib/Math/DifferenceSet/Planar.pm',
    PREREQ_PM           => {
        'Carp',                     => 0,
        'DBD::SQLite'               => '1.48',
        'DBIx::Class'               => 0,
        'File::Share'               => 0,
        'File::Spec'                => 0,
        'Math::Prime::Util'         => '0.59',
    },
    ABSTRACT_FROM       => 'lib/Math/DifferenceSet/Planar.pm',
    AUTHOR              => 'Martin Becker <becker-cpan-mp (at) cozap.com>',
    SIGN                => 1,
    LICENSE             => 'artistic_2',
    META_MERGE          => {
        'meta-spec'     => { version => 2 },
        provides        => \%versions,
        dynamic_config  => 0,
        resources       => {
            bugtracker      => {
                web => "https://github.com/mhasch/perl-$DN/issues",
            },
            homepage        => 'https://vera.in-ulm.de/planar-diffsets/',
            license         => [
                'https://www.perlfoundation.org/artistic-license-20.html',
            ],
            repository      => {
                url  => "git://github.com/mhasch/perl-$DN.git",
                web  => "https://github.com/mhasch/perl-$DN",
                type => 'git',
            },
        },
    },
    MIN_PERL_VERSION    => '5.010',
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker'       => '7.06',
        'File::ShareDir::Install'   => 0,
        'File::Spec'                => 0,
    },
    TEST_REQUIRES       => {
        'Test::More'                => 0,
    },
);
