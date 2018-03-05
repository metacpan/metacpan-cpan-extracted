use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'HTTP::Caching',
    AUTHOR           => q{Theo van Hoesel <Th.J.v.Hoesel@THEMA-MEDIA.nl>},
    VERSION_FROM     => 'lib/HTTP/Caching.pm',
    ABSTRACT_FROM    => 'lib/HTTP/Caching.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'           => 0,
    },
    BUILD_REQUIRES => {
        'Test::Most'                    => 0,
        'Test::MockObject'              => 0,
        'HTTP::Request'                 => 0,
        'HTTP::Response'                => 0,
        'Readonly'                      => 0,
    },
    PREREQ_PM => {
        'Carp'                          => 0,
        'Digest::MD5'                   => 0,
        'HTTP::Method'                  => 0,
        'List::MoreUtils'               => 0,
        'Monkey::Patch::Action'         => 0,
        'Moo'                           => 0,
        'MooX::Types::MooseLike::Base'  => 0,
        'Time::HiRes'                   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'HTTP-Caching-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/THEMA-MEDIA/HTTP-Caching.git',
                web  => 'https://github.com/THEMA-MEDIA/HTTP-Caching',
            },
        }})
     : ()
    ),
);
