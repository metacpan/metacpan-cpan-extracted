#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dist::Zilla::PluginBundle::MANWAR',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Dist/Zilla/PluginBundle/MANWAR.pm',
    ABSTRACT_FROM      => 'lib/Dist/Zilla/PluginBundle/MANWAR.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '1.001014',
    },
    PREREQ_PM   => {
        'Moose' => 0,
        'Dist::Zilla::Plugin::PkgVersion'            => 0,
        'Dist::Zilla::Plugin::PodVersion'            => 0,
        'Dist::Zilla::Plugin::MinimumPerlFast'       => 0,
        'Dist::Zilla::Plugin::AutoPrereqs'           => 0,
        'Dist::Zilla::Plugin::MetaJSON'              => 0,
        'Dist::Zilla::Plugin::MakeMaker'             => 0,
        'Dist::Zilla::Plugin::Manifest'              => 0,
        'Dist::Zilla::Plugin::GithubMeta'            => 0,
        'Dist::Zilla::Plugin::MetaProvides::Package' => 0,
        'Dist::Zilla::Role::PluginBundle::Easy'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dist-Zilla-PluginBundle-MANWAR-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Dist::Zilla::PluginBundle::MANWAR' => { file => 'lib/Dist/Zilla/PluginBundle/MANWAR.pm', version => '0.08' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Dist-Zilla-PluginBundle-MANWAR.git',
                web  => 'https://github.com/manwar/Dist-Zilla-PluginBundle-MANWAR',
            },
        }})
     : ()
    ),
);
