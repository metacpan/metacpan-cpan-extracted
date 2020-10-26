use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

die "OS unsupported" unless $^O eq 'darwin';

WriteMakefile(
    NAME             => 'Mac::OSA::Dialog::Tiny',
    AUTHOR           => q{LNATION <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Mac/OSA/Dialog/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Mac/OSA/Dialog/Tiny.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
       'Import::Export' => '1.00',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mac-OSA-Dialog-Tiny-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Mac-OSA-Dialog-Tiny.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Mac-OSA-Dialog-Tiny',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
    }
);
