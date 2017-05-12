use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR'   => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Draw text along a polyline',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Image-Magick-PolyText-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'Image-Magick-PolyText',
	NAME		=> 'Image::Magick::PolyText',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'File::Temp'		=> 0,
		'Font::FreeType'	=> 0.07,
		'Image::Magick'		=> undef,
		'List::Maker'		=> 0.005,
		'Math::Bezier'		=> 0.01,
		'Math::Derivative'	=> 0.04,
		'Math::Interpolate'	=> 1.06,
		'Moo'				=> 2.003000,
		'parent'			=> 0,
		'POSIX'				=> 0,
		'Readonly'			=> 2.05,
		'strict'			=> 0,
		'Types::Standard'	=> 1.000005,
		'Time::Elapsed'		=> 0.32,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.51,
	},
	VERSION_FROM   => 'lib/Image/Magick/PolyText.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Image-Magick-PolyText',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Image-Magick-PolyText.git',
				web		=> 'https://github.com/ronsavage/Image-Magick-PolyText',
			},
		},
	};
}

WriteMakefile(%params);
