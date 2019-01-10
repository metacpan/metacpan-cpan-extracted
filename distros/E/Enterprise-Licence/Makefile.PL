use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Enterprise::Licence',
    AUTHOR           => q{LNATION <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Enterprise/Licence.pm',
    ABSTRACT_FROM    => 'lib/Enterprise/Licence.pm',
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
		'DateTime' => '1.50',
		'Math::BigInt' => '1.999816',
		'Compress::Huffman' => '0.08',
		'Shannon::Entropy' => '1.101011',
		'Bijection' => '1.00',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Enterprise-Licence-*' },
);
