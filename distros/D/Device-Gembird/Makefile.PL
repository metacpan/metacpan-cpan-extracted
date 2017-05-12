use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Device::Gembird',
    AUTHOR           => q{Leandr Khaliullov <leandr@cpan.org>},
    VERSION_FROM     => 'lib/Device/Gembird.pm',
    ABSTRACT_FROM    => 'lib/Device/Gembird.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IO::Socket'            => 0,
        'IO::Select'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Device-Gembird-*' },
);
