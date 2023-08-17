use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    ABSTRACT           => 'dynamically create plugins from a bundle',
    AUTHOR             => 'Sven Kirmess <sven.kirmess@kzone.ch>',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    DISTNAME         => 'Dist-Zilla-Plugin-Code',
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => '5.006',
    NAME             => 'Dist::Zilla::Plugin::Code',
    PREREQ_PM        => {
        Carp                                       => 0,
        'Config::MVP'                              => '2.200012',
        'Dist::Zilla::Role::AfterBuild'            => 0,
        'Dist::Zilla::Role::AfterRelease'          => 0,
        'Dist::Zilla::Role::BeforeArchive'         => 0,
        'Dist::Zilla::Role::BeforeBuild'           => 0,
        'Dist::Zilla::Role::BeforeRelease'         => 0,
        'Dist::Zilla::Role::BuildRunner'           => 0,
        'Dist::Zilla::Role::EncodingProvider'      => 0,
        'Dist::Zilla::Role::FileFinder'            => 0,
        'Dist::Zilla::Role::FileGatherer'          => 0,
        'Dist::Zilla::Role::FileMunger'            => 0,
        'Dist::Zilla::Role::FilePruner'            => 0,
        'Dist::Zilla::Role::InstallTool'           => 0,
        'Dist::Zilla::Role::LicenseProvider'       => 0,
        'Dist::Zilla::Role::MetaProvider'          => 0,
        'Dist::Zilla::Role::NameProvider'          => 0,
        'Dist::Zilla::Role::Plugin'                => 0,
        'Dist::Zilla::Role::PluginBundle'          => 0,
        'Dist::Zilla::Role::PrereqSource'          => 0,
        'Dist::Zilla::Role::ReleaseStatusProvider' => 0,
        'Dist::Zilla::Role::Releaser'              => 0,
        'Dist::Zilla::Role::TestRunner'            => 0,
        'Dist::Zilla::Role::VersionProvider'       => 0,
        Moose                                      => 0,
        'MooseX::Types::Moose'                     => 0,
        'namespace::autoclean'                     => 0,
        strict                                     => 0,
        warnings                                   => 0,
    },
    TEST_REQUIRES => {
        'Capture::Tiny'                         => 0,
        Cwd                                     => 0,
        'Dist::Zilla::File::InMemory'           => 0,
        'Dist::Zilla::Role::FileFinderUser'     => 0,
        'Dist::Zilla::Role::PluginBundle::Easy' => 0,
        Exporter                                => 0,
        'File::Basename'                        => 0,
        'File::Path'                            => '2.07',
        'File::Spec'                            => 0,
        'File::Spec::Functions'                 => 0,
        'Test::DZil'                            => 0,
        'Test::Fatal'                           => 0,
        'Test::More'                            => '0.88',
        lib                                     => 0,
    },
    VERSION => '0.008',
    test    => {
        TESTS => 't/*.t',
    },
);

my %FallbackPrereqs = (
    'Capture::Tiny'                            => 0,
    Carp                                       => 0,
    'Config::MVP'                              => '2.200012',
    Cwd                                        => 0,
    'Dist::Zilla::File::InMemory'              => 0,
    'Dist::Zilla::Role::AfterBuild'            => 0,
    'Dist::Zilla::Role::AfterRelease'          => 0,
    'Dist::Zilla::Role::BeforeArchive'         => 0,
    'Dist::Zilla::Role::BeforeBuild'           => 0,
    'Dist::Zilla::Role::BeforeRelease'         => 0,
    'Dist::Zilla::Role::BuildRunner'           => 0,
    'Dist::Zilla::Role::EncodingProvider'      => 0,
    'Dist::Zilla::Role::FileFinder'            => 0,
    'Dist::Zilla::Role::FileFinderUser'        => 0,
    'Dist::Zilla::Role::FileGatherer'          => 0,
    'Dist::Zilla::Role::FileMunger'            => 0,
    'Dist::Zilla::Role::FilePruner'            => 0,
    'Dist::Zilla::Role::InstallTool'           => 0,
    'Dist::Zilla::Role::LicenseProvider'       => 0,
    'Dist::Zilla::Role::MetaProvider'          => 0,
    'Dist::Zilla::Role::NameProvider'          => 0,
    'Dist::Zilla::Role::Plugin'                => 0,
    'Dist::Zilla::Role::PluginBundle'          => 0,
    'Dist::Zilla::Role::PluginBundle::Easy'    => 0,
    'Dist::Zilla::Role::PrereqSource'          => 0,
    'Dist::Zilla::Role::ReleaseStatusProvider' => 0,
    'Dist::Zilla::Role::Releaser'              => 0,
    'Dist::Zilla::Role::TestRunner'            => 0,
    'Dist::Zilla::Role::VersionProvider'       => 0,
    Exporter                                   => 0,
    'File::Basename'                           => 0,
    'File::Path'                               => '2.07',
    'File::Spec'                               => 0,
    'File::Spec::Functions'                    => 0,
    Moose                                      => 0,
    'MooseX::Types::Moose'                     => 0,
    'Test::DZil'                               => 0,
    'Test::Fatal'                              => 0,
    'Test::More'                               => '0.88',
    lib                                        => 0,
    'namespace::autoclean'                     => 0,
    strict                                     => 0,
    warnings                                   => 0,
);

if ( !eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
    delete $WriteMakefileArgs{CONFIGURE_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);

# vim: ts=4 sts=4 sw=4 et: syntax=perl
