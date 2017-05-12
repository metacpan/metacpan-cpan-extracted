use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'IP::Info',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/IP/Info.pm',
    ABSTRACT_FROM      => 'lib/IP/Info.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON'               => 0,
        'Moo'                => 0,
        'namespace::clean'   => 0,
        'Throwable'          => 0,
        'HTTP::Tiny'         => 0,
        'Digest::MD5'        => '2.36',
        'Data::Validate::IP' => '0.10',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IP-Info-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'IP::Info'                       => { file => 'lib/IP/Info.pm'                    , version => '0.17' },
            'IP::Info::Response'             => { file => 'lib/IP/Info/Response.pm'           , version => '0.17' },
            'IP::Info::Response::Network'    => { file => 'lib/IP/Info/Response/Network.pm'   , version => '0.17' },
            'IP::Info::Response::Location'   => { file => 'lib/IP/Info/Response/Location.pm'  , version => '0.17' },
            'IP::Info::UserAgent'            => { file => 'lib/IP/Info/UserAgent.pm'          , version => '0.17' },
            'IP::Info::UserAgent::Exception' => { file => 'lib/IP/Info/UserAgent/Exception.pm', version => '0.17' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/IP-Info.git',
                web  => 'https://github.com/manwar/IP-Info',
            },
        }})
     : ()
    ),
);
