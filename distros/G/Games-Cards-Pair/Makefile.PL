use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Games::Cards::Pair',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Games/Cards/Pair.pm',
    ABSTRACT_FROM      => 'lib/Games/Cards/Pair.pm',
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'script/play-pelmanism' ],
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Attribute::Memoize' => 1.01,
        'List::Util'         => 1.19,
        'List::MoreUtils'    => 0.33,
        'Term::Screen::Lite' => 0,
        'Moo'                => '2.000000',
        'namespace::clean'   => '0.24',
        'Type::Tiny'         => '1.000005',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Games-Cards-Pair-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Games::Cards::Pair'         => { file => 'lib/Games/Cards/Pair.pm'       , version => '0.17' },
            'Games::Cards::Pair::Card'   => { file => 'lib/Games/Cards/Pair/Card.pm'  , version => '0.17' },
            'Games::Cards::Pair::Params' => { file => 'lib/Games/Cards/Pair/Params.pm', version => '0.17' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Games-Cards-Pair.git',
                web  => 'https://github.com/manwar/Games-Cards-Pair',
            },
        }})
     : ()
    ),
);
