#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'File::Same',
    AUTHOR             => q{Matt Sergeant <MSERGEANT@cpan.org>},
    VERSION_FROM       => 'lib/File/Same.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES     => {
        'Test::More'   => '1.001014',
    },
    PREREQ_PM          => {
        'strict'       => 0,
        'Digest::MD5'  => 0,
        'File::Spec'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-Same-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'File::Same' => { file => 'lib/File/Same.pm', version => '0.11' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/File-Same.git',
                web  => 'https://github.com/manwar/File-Same',
            },
        }})
     : ()
    ),
);
