use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Geo::Coder::All',
    AUTHOR           => q{Rohit Deshmukh <raigad1630@gmail.com>},
    VERSION_FROM     => 'lib/Geo/Coder/All.pm',
    ABSTRACT_FROM    => 'lib/Geo/Coder/All.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moose'                     => 0,
        'namespace::autoclean'      => 0,
        'Data::Dumper'              => 0,
        'Carp'                      => 0,
        'Locale::Codes::Country'    => '3.30',
        'Geo::Coder::Google'        => '0',
        #'Geo::Coder::Bing'          => '0',
        #'Geo::Coder::OSM'           => '0',
        #'Geo::Coder::Ovi'           => '0',
        #'Geo::Coder::TomTom'        => '0',
        'Module::Runtime'           => '0',
    },
    META_MERGE  => {
        "meta-spec" => { version => 2 },
        resources   => {
                    "bugtracker" => {
                               "web" => "https://github.com/raigad/geo-coder-all/issues"
                        },
                    "homepage" => "http://search.cpan.org/~raigad/geo-coder-all/",
                    repository  => {
                                type => 'git',
                                url => 'git://github.com/raigad/geo-coder-all.git',
                                web => 'https://github.com/raigad/geo-coder-all',
                    },
    },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-Coder-All-*' },
);
