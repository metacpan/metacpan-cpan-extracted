use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Locale::Country::Extra',
    AUTHOR           => q{binary.com <perl@binary.com>},
    VERSION_FROM     => 'lib/Locale/Country/Extra.pm',
    ABSTRACT         => 'Standard and IDD codes for Country identification, with Multilingual support',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Test::NoWarnings' => 0,
    },
    PREREQ_PM => {
        'Locale::Country' => '0',
        'Locale::Country::Multilingual' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Locale-Country-Extra-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'https://github.com/binary-com/perl-Locale-Country-Extra.git',
                    web => 'https://github.com/binary-com/perl-Locale-Country-Extra',
                },
              }
          } )
     : ()
    ),
);
