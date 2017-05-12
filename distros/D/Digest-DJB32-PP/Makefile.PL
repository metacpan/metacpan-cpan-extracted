use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Digest::DJB32::PP',
    AUTHOR           => q{Richard THIBERT <thibs@cpan.org>},
    VERSION_FROM     => 'lib/Digest/DJB32/PP.pm',
    ABSTRACT_FROM    => 'lib/Digest/DJB32/PP.pm',
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
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Digest-DJB32-PP-*' },
);
