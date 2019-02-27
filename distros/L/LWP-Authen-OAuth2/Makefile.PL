use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LWP::Authen::OAuth2',
    AUTHOR           => q{Ben Tilly <btilly@gmail.com>},
    VERSION_FROM     => 'lib/LWP/Authen/OAuth2.pm',
    ABSTRACT_FROM    => 'lib/LWP/Authen/OAuth2.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP'               => 4.0,
        'LWP::Protocol::https' => 6.0,
        'Mozilla::CA'       => 20000101,
        'JSON'              => 2,
        'Module::Load'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LWP-Authen-OAuth2-*' },
	test => { TESTS => "t/*.t t/LWP/Authen/*.t t/LWP/Authen/OAuth2/*.t t/LWP/Authen/OAuth2/ServiceProvider/*.t t/LWP/Authen/OAuth2/ServiceProvider/Line/*.t t/LWP/Authen/OAuth2/AccessToken/*.t" },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/domm/perl-oauth2.git',
             web  => 'https://github.com/domm/perl-oauth2',
         },
     }})
     : ()
),
);
