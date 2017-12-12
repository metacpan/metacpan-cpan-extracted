use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Colorize::Helper',
    AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM     => 'lib/Log/Colorize/Helper.pm',
    ABSTRACT_FROM    => 'lib/Log/Colorize/Helper.pm',
    LICENSE          => 'freebsd',
	INST_SCRIPT => 'bin',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
		'Error::Helper'=>'1.0.0',
			'String::ShellQuote'=>'1.04',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Colorize-Helper-*' },
	);
