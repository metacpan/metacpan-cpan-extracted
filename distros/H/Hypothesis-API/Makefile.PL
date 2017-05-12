use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Hypothesis::API',
    AUTHOR           => q{Brandon E. Barker <brandon.barker@cornell.edu>},
    VERSION_FROM     => 'lib/Hypothesis/API.pm',
    ABSTRACT_FROM    => 'lib/Hypothesis/API.pm',
    LICENSE          => 'artistic_2',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                 type => 'git',
                 url  => 'https://github.com/bbarker/Hypothesis-API.git',
                 web  => 'https://github.com/bbarker/Hypothesis-API',
            },
        },
    },
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    #For below, See also cpanfile for alternative use
    PREREQ_PM => { #Simple way to find minimal req version?
        'namespace::autoclean'  => 0.0,
        'Moose'                 => 0.0,
        'Storable'              => 0.0,
        'Try::Tiny'             => 0.0,
        'CGI::Cookie'           => 0.0,
        'HTTP::Cookies'         => 0.0,
        'HTTP::Request'         => 0.0,
        'JSON'                  => 0.0,
	'LWP::Protocol::https'  => 0.0,
        'LWP::UserAgent'        => 0.0,
        'URI'                   => 0.0,
        'URI::Encode'           => 0.0,
    }, 
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hypothesis-API-*' },
);
