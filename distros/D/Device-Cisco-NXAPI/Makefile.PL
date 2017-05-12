use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Device::Cisco::NXAPI',
    AUTHOR           => q{Greg Foletta <greg@foletta.org>},
    VERSION_FROM     => 'lib/Device/Cisco/NXAPI.pm',
    ABSTRACT_FROM    => 'lib/Device/Cisco/NXAPI.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.020,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
		'File::Slurp' => 9999.19,
		'JSON' => 2.90,
    },
    PREREQ_PM => {
       	'Array::Utils' => 0.5, 
		'Carp' => 1.36,
		'Data::Dumper' => 2.161,
		'HTTP::Request' => 6.11,
		'JSON' => 2.90,
		'List::MoreUtils' => 0.413,
		'List::Util' => 1.47,
		'LWP::UserAgent' => 6.15,
		'Modern::Perl' => 1.20170117,
		'Moose' => 2.1807,
		'Params::Validate' => 1.22,
		'URI' => 1.71,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Switch-NXAPI-*' },
);
