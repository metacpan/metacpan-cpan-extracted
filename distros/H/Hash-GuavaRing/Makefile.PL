use 5.010;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Hash::GuavaRing',
	VERSION_FROM      => 'lib/Hash/GuavaRing.pm', # finds $VERSION
	PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM     => 'lib/Hash/GuavaRing.pm', # retrieve abstract from module
	AUTHOR            => 'Sveta Kotleta <sveta@svetakotleta.ru>',
	LIBS              => [''], # e.g., '-lm'
	DEFINE            => '-Wall -Wno-shift-count-overflow -Wno-constant-conversion', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	LICENSE           => 'perl_5',
	# Un-comment this if you add C files to link with later:
	# OBJECT            => '$(O_FILES)', # link all the C files too
);
