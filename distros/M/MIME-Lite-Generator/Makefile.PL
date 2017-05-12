use 5.008000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'MIME::Lite::Generator',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/MIME/Lite/Generator.pm', # finds $VERSION
	PREREQ_PM         => { 'MIME::Lite' => 3.020 }, # e.g., Module::Name => 1.1
	BUILD_REQUIRES    => { 'Test::More' => 0.88 },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => {
		resources => {repository => 'https://github.com/olegwtf/p5-MIME-Lite-Generator'},
	},
	ABSTRACT_FROM     => 'lib/MIME/Lite/Generator.pm', # retrieve abstract from module
	AUTHOR            => 'Oleg G <oleg@cpan.org>'
);
