use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::IPinfo',
    AUTHOR           => q{ipinfo.io <support@ipinfo.io>},
    VERSION_FROM     => 'lib/Geo/IPinfo.pm',
    ABSTRACT_FROM    => 'lib/Geo/IPinfo.pm',
    LICENSE          => 'apache_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'LWP::UserAgent'          => '0',
        'JSON'                    => '0',
        'Cache::LRU'              => '0',
        'Net::CIDR'               => '0.22',
        'Net::CIDR::Set'          => '0',
        'LWP::Protocol::https'    => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-IPinfo-*' },

    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        keywords    => ['geo', 'network'],
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ipinfo/perl',
                web  => 'https://github.com/ipinfo/perl',
                },
            bugtracker => {
                web    => "https://github.com/ipinfo/perl/issues",
                },
            homepage => 'https://ipinfo.io',
            },
        },
);

package MY;
