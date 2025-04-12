use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'JQ::Lite',
    VERSION_FROM     => 'lib/JQ/Lite.pm',
    ABSTRACT         => 'A lightweight jq-like JSON query engine in Perl',
    AUTHOR           => 'Kawamura Shingo <pannakoota1@gmail.com>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'JSON::PP'   => 0,
        'Test::More' => 0,
        'FindBin'    => 0,
    },
    EXE_FILES        => ['bin/jq-lite'],
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/kawamurashingo/JQ-Lite.git',
                web  => 'https://github.com/kawamurashingo/JQ-Lite',
            },
            bugtracker => {
                web => 'https://github.com/kawamurashingo/JQ-Lite/issues',
            },
        },
        no_index => {
            directory => [ 't', 'inc' ],
        },
    },
);
