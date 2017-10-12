#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'IP::CountryFlag',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/IP/CountryFlag.pm',
    ABSTRACT_FROM      => 'lib/IP/CountryFlag.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'autodie'               => '2.06',
        'Moo'                   => '2.000000',
        'namespace::clean'      => '0.24',
        'Throwable'             => 0,
        'HTTP::Tiny'            => 0,
        'Data::Validate::IP'    => '0.10',
        'File::Spec::Functions' => '3.30',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'IP-CountryFlag-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'IP::CountryFlag'                       => { file => 'lib/IP/CountryFlag.pm',                     version => '0.11' },
            'IP::CountryFlag::Params'               => { file => 'lib/IP/CountryFlag/Params.pm',              version => '0.11' },
            'IP::CountryFlag::UserAgent'            => { file => 'lib/IP/CountryFlag/UserAgent.pm',           version => '0.11' },
            'IP::CountryFlag::UserAgent::Exception' => { file => 'lib/IP/CountryFlag/UserAgent/Exception.pm', version => '0.11' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/IP-CountryFlag.git',
                web  => 'https://github.com/manwar/IP-CountryFlag',
            },
        }})
     : ()
    ),
);
