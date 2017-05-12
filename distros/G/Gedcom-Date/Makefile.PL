use strict;
use warnings;

use Config;

use ExtUtils::MakeMaker;

use File::Spec;
use File::Temp;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Eugene van der Pijll (pijll@gmx.net)',
		ABSTRACT => 'Perl class for interpreting dates in Gedcom files',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Gedcom-Date-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Gedcom-Date',
	NAME      => 'Gedcom::Date',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Config' => 0,
		'DateTime' => 1.36,
		'DateTime::Locale' => 1.05,
		'File::Spec' => 0,
		'File::Temp' => 0,
		'overload' => 0,
		'Params::Validate' => 0,
		'strict' => 0,
		'vars' => 0,
		'warnings' => 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.302052,
	},
	VERSION_FROM => 'lib/Gedcom/Date.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Gedcom-Date',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Gedcom-Date.git',
				web		=> 'https://github.com/ronsavage/Gedcom-Date',
			},
		},
	};
}

WriteMakefile(%params);
