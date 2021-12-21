use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Finance::Nadex',
    AUTHOR           => q{Mtu Mzuri <mhandisi@cpan.org>},
    VERSION_FROM     => 'lib/Finance/Nadex.pm',
    ABSTRACT_FROM    => 'lib/Finance/Nadex.pm',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON'                 => 4.00,
	'Test::More'           => 0,
	'Test::Exception'      => 0,
        'Test::LWP::UserAgent' => 0.033,
	'LWP::UserAgent'       => 0,
	'Carp'                 => 0,
	'HTTP::Response'       => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Finance-Nadex-*' },
);
