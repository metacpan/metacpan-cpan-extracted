#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'HEAT::Crypto',
	DISTNAME       => 'HEAT-Crypto',
	VERSION_FROM   => 'lib/HEAT/Crypto.pm',
	MIN_PERL_VERSION => '5.006',
	TEST_REQUIRES  => { 'Test::More' => 0 },
	PREREQ_PM      => { 
		'Carp' => 0,
		'Digest::SHA' => 0,
		'CryptX' => 0,
	},
	LICENSE        => 'perl',
    AUTHOR         => 'Toma Mazilu',
    LIBS           => [''],
    DEFINE         => '',
    INC            => '-I.',
    OBJECT         => 'Crypto.o curve25519_i64.o',
	META_MERGE     => { resources  => { repository => 'https://github.com/tomushkin/heat-perl', bugtracker => 'https://github.com/tomushkin/heat-perl/issues' } },
);
