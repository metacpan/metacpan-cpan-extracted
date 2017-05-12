use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Lim::Plugin::Zonalizer',
    AUTHOR        => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM  => 'lib/Lim/Plugin/Zonalizer.pm',
    ABSTRACT_FROM => 'lib/Lim/Plugin/Zonalizer.pm',
    EXE_FILES     => [ 'bin/zonalizer-collector', 'bin/zonalizer-couchdb-database' ],
    (
        !eval { ExtUtils::MakeMaker->VERSION( 6.3002 ) }
        ? ()
        : ( LICENSE => 'perl' )
    ),
    (
        eval { ExtUtils::MakeMaker->VERSION( 6.5503 ) }
        ? (
            BUILD_REQUIRES => {
                'Test::More'        => 0,
                'common::sense'     => 3,
                'Lim'               => 0.20,
                'Getopt::Long'      => 2.38,
                'Scalar::Util'      => 1,
                'URI::Escape::XS'   => 0.11,
                'Data::UUID'        => 0,
                'Clone'             => 0,
                'AnyEvent::CouchDB' => 1.31,
                'AnyEvent::HTTP'    => 2.13,
                'JSON'              => 0,
                'HTTP::Status'      => 0,
                'JSON::XS'          => 0,
                'Zonemaster'        => 0,
                'MooseX::Getopt'    => 0,
                'Net::LDNS'         => 0.75,
            },
            PREREQ_PM => {
                'common::sense'     => 3,
                'Lim'               => 0.20,
                'Getopt::Long'      => 2.38,
                'Scalar::Util'      => 1,
                'URI::Escape::XS'   => 0.11,
                'Data::UUID'        => 0,
                'Clone'             => 0,
                'AnyEvent::CouchDB' => 1.31,
                'AnyEvent::HTTP'    => 2.21,
                'JSON'              => 0,
                'HTTP::Status'      => 0,
                'JSON::XS'          => 0,
                'Zonemaster'        => 0,
                'MooseX::Getopt'    => 0,
                'Net::LDNS'         => 0.75,
            }
          )
        : (
            PREREQ_PM => {
                'Test::More'        => 0,
                'common::sense'     => 3,
                'Lim'               => 0.20,
                'Getopt::Long'      => 2.38,
                'Scalar::Util'      => 1,
                'URI::Escape::XS'   => 0.11,
                'Data::UUID'        => 0,
                'Clone'             => 0,
                'AnyEvent::CouchDB' => 1.31,
                'AnyEvent::HTTP'    => 2.21,
                'JSON'              => 0,
                'HTTP::Status'      => 0,
                'JSON::XS'          => 0,
                'Zonemaster'        => 0,
                'MooseX::Getopt'    => 0,
                'Net::LDNS'         => 0.75,
            }
        )
    ),
    (
        !eval { ExtUtils::MakeMaker->VERSION( 6.46 ) }
        ? ()
        : (
            META_ADD => {
                resources => {
                    homepage   => 'https://github.com/jelu/lim-plugin-zonalizer',
                    repository => 'https://github.com/jelu/lim-plugin-zonalizer',
                    bugtracker => 'https://github.com/jelu/lim-plugin-zonalizer/issues',
                },
            }
        )
    ),
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Lim-Plugin-Zonalizer-*' },
);
