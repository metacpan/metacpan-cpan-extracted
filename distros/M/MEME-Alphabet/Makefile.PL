use 5.0120;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MEME::Alphabet',
    AUTHOR           => [
        'James Johnson',
        'Timothy L. Bailey <meme-suite@uw.edu>',
    ],
    VERSION_FROM     => 'lib/MEME/Alphabet.pm',
    ABSTRACT_FROM    => 'lib/MEME/Alphabet.pm',
    LICENSE          => 'restricted',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.0120',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'            => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'                     => '0',
        'Array::Compare'                 => '0'
    },
    PREREQ_PM => {
                'Carp'                   => '0',
                'Exporter'               => '0',
                'Fcntl'                  => '0',
                'feature'                => '0',
                'strict'                 => '0',
                'utf8'                   => '0',
                'version'                => '0',
                'warnings'               => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MEME-Alphabet-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage    => 'http://meme-suite.org',
            repository  => {
                type        => 'hg',
                url         => 'https://cviner2@bitbucket.org/cviner2/meme-alphabet',
                web         => 'https://bitbucket.org/cviner2/meme-alphabet',
            },
            bugtracker  => {
                web         => 'https://bitbucket.org/cviner2/meme-alphabet/issues',
            },
        },
        provides => {
            'MEME::Alphabet' => {
                file    => 'lib/MEME/Alphabet.pm',
                version => 'v4.12.0.1.3',
          },
        },
    },
);
