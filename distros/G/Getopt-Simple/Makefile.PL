use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'A simple-to-use interface to Getopt::Long',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST Getopt-Simple-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'Getopt-Simple',
	NAME			=> 'Getopt::Simple',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Getopt::Long	=> 0,
		Test::More		=> 0,
		Test::Pod		=> 0,
	},
	VERSION_FROM	=> 'lib/Getopt/Simple.pm'
);
