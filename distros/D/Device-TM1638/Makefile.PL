use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Device::TM1638',
    AUTHOR           => q{Adam Wien <awien@cpan.org>},
    VERSION_FROM     => 'lib/Device/TM1638.pm',
    ABSTRACT_FROM    => 'lib/Device/TM1638.pm',
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
	'Device::BCM2835'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Device-TM1638-*' },
);
