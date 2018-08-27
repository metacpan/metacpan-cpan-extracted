use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'List::Unique::DeterministicOrder',
    AUTHOR           => q{SLAFFAN <shawnlaffan@gmail.com>},
    VERSION_FROM     => 'lib/List/Unique/DeterministicOrder.pm',
    ABSTRACT_FROM    => 'lib/List/Unique/DeterministicOrder.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        'rlib' => 0,
    },
    PREREQ_PM => {
        'List::Util' => 1.45,
        'Carp' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/perl-List-Unique-DeterministicOrder',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-List-Unique-DeterministicOrder/issues/',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'List-Unique-DeterministicOrder-*' },
);
