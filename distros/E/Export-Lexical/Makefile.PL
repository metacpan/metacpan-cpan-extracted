#!perl

use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'Export::Lexical',
    AUTHOR              => 'Chris Grau <cgrau@cpan.org>',
    VERSION_FROM        => 'lib/Export/Lexical.pm',
    ABSTRACT_FROM       => 'lib/Export/Lexical.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'Test::Exception'  => 0,
        'Test::Warn'       => 0,
    },
    "MIN_PERL_VERSION" => 5.01,
    "META_MERGE" => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/sirhc/perl-Export-Lexical',
                url  => 'https://github.com/sirhc/perl-Export-Lexical.git',
            },
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Export-Lexical-*' },
);

delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION(6.45) };

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION(6.48) };

WriteMakefile(%WriteMakefileArgs);
