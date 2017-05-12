use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'IP::IPwhere',
    AUTHOR           => q{Orange <bollwarm@ijz.me>},
    VERSION_FROM     => 'lib/IP/IPwhere.pm',
    ABSTRACT_FROM    => 'lib/IP/IPwhere.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },

       PREREQ_PM                => {
                "LWP::Simple"   => 0,
                'JSON'  => 0,
                'Encode'         => 0,
                'Data::Dumper'   => 0,
                'POSIX'          => 0,
        },
       META_MERGE => {
          'meta-spec' => { version => 2 },
           resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bollwarm/IP-IPwhere',
                web  => 'http://ijz.me',
            },
        },
    },

);
