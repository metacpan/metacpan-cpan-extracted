#-*- perl -*-
#-*- coding: us-ascii -*-

use 5.007003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Encode::ISO2022',
    VERSION_FROM  => 'lib/Encode/ISO2022.pm',
    ABSTRACT_FROM => 'lib/Encode/ISO2022.pm',
    AUTHOR        => 'Hatuka*nezumi - IKEDA Soji <hatuka@nezumi.nu>',
    LICENSE       => 'perl',
    MIN_PERL_VERSION   => '5.007003',
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 0,},
    BUILD_REQUIRES     => {
	'ExtUtils::MakeMaker' => 0,
        'Test::More'          => 0,
    },
    PREREQ_PM     => {
	'Encode'     => '2.10',
    },
    META_MERGE    => {
	resources     => {
	    license       => 'http://dev.perl.org/licenses/',
	    repository    => 'http://hatuka.nezumi.nu/repos/Encode-ISO2022/',
	},
    },
);
