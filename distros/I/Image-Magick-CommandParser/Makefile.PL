use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Parse any command line acceptable to convert or mogrify',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Image-Magick-CommandParser-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Image-Magick-CommandParser',
	NAME      => 'Image::Magick::CommandParser',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Data::Section::Simple'	=> 0.07,
		'File::Glob'			=> 0,
		'File::Slurper'			=> 0.008,
		'Getopt::Long'			=> 0,
		'Log::Handler'			=> 0.88,
		'Moo'					=> 2.002004,
		'Set::Array'			=> 0.30,
		'Set::FA::Element'		=> 2.00,
		'Pod::Usage'			=> 1.67,
		'strict'				=> 0,
		'Types::Standard'		=> 1.00005,
		'warnings'				=> 0,
	},
	TEST_REQUIRES =>
	{
		'File::Spec'		=> 0,
		'File::Temp'		=> 0,
		'Test::Pod'			=> 1.51,
		'Test::Simple'		=> 1.302052, # For Test::More.
	},
	VERSION_FROM => 'lib/Image/Magick/CommandParser.pm',
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
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Image-Magick-CommandParser',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Image-Magick-CommandParser.git',
				web		=> 'https://github.com/ronsavage/Image-Magick-CommandParser',
			},
		},
	};
}

WriteMakefile(%params);
