use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Use Image::Magick to create charts',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Image-Magick-Chart-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'Image-Magick-Chart',
	NAME		=> 'Image::Magick::Chart',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Carp'				=> 0,
		'Image::Magick'		=> undef,
		'Moo'				=> 2.003000,
		'parent'			=> 0,
		'perl'				=> 5.006002,
		'strict'			=> 0,
		'Types::Standard'	=> 1.000005,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.51,
	},
	VERSION_FROM	=> 'lib/Image/Magick/Chart.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Image-Magick-Chart',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Image-Magick-Chart.git',
				web		=> 'https://github.com/ronsavage/Image-Magick-Chart',
			},
		},
	};
}

WriteMakefile(%params);
