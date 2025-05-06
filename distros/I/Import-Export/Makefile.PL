use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Import::Export',
	AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
	VERSION_FROM     => 'lib/Import/Export.pm',
	ABSTRACT_FROM    => 'lib/Import/Export.pm',
	LICENSE          => 'artistic_2',
	PL_FILES         => {},
	MIN_PERL_VERSION => '5.006',
	macro => { TARFLAGS   => "--format=ustar -c -v -f" },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Carp' => '0',
		'namespace::clean' => '0.27'
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Import-Export-*' },
);
