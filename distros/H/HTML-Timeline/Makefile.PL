use strict;
use warnings;

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Convert a Gedcom file into a Timeline file',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST HTML-Timeline-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'HTML-Timeline',
	EXE_FILES => ['bin/timeline.pl'],
	NAME      => 'HTML::Timeline',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'accessors::classic'	=> 1.01,
		'Capture::Tiny'			=> 0.46,
		'Carp'					=> 0,
		'Gedcom'				=> 1.20,
		'Gedcom::Date'			=> 0.10,
		'Getopt::Long'			=> 0,
		'HTML::Template'		=> 2.95,
		'Path::Class'			=> 0.37,
		'perl'					=> 0,
		'Pod::Usage'			=> 0,
		'strict'				=> 0,
		'warnings'				=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More' => 1.001002,
	},
	VERSION_FROM => 'lib/HTML/Timeline.pm',
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
		resources =>
		{
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Timeline',
			license		=> 'http://opensource.org/licenses/Artistic-2.0',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/HTML-Timeline.git',
				web		=> 'https://github.com/ronsavage/HTML-Timeline',
			},
		},
	};
}

WriteMakefile(%params);
