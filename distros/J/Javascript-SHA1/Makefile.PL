use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Calculate the SHA1 digest of a CGI form field',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST Javascript-SHA1-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'Javascript-SHA1',
	NAME			=> 'Javascript::SHA1',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	VERSION_FROM	=> 'lib/Javascript/SHA1.pm'
);
