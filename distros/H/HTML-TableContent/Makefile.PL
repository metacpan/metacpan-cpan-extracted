use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'HTML::TableContent',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/HTML/TableContent.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Module::Metadata' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'             => "1.22",
        'Moo'              => "1.001001",
        'MooX::ReturnModifiers' => "0.03",
        'HTML::Parser'     => "3.71",
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTML-TableContent-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/HTML-TableContent.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/HTML-TableContent',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
    },
);
