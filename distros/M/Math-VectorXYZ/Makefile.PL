use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Math::VectorXYZ',
    AUTHOR           => q{Ryan Matthew <rmatthew@cpan.org>},
    VERSION_FROM     => 'lib/Math/VectorXYZ.pm',
    ABSTRACT_FROM    => 'lib/Math/VectorXYZ.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp'              => 0,
        'Exporter'          => 0,
        'Math::Trig'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-VectorXYZ-*' },
);
