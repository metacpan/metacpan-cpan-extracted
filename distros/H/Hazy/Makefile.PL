use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Hazy',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Hazy.pm',
    ABSTRACT_FROM    => 'lib/Hazy.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    	'Cwd' => '0',
    },
    PREREQ_PM => {
    	'strict' => '0',
	'warnings' => '0',
	'Cwd' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Hazy-*' },
);
