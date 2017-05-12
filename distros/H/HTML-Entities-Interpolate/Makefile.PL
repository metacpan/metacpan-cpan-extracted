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
		'AUTHOR'   => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Call HTML::Entities::encode_entities, via a hash, within a string',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST HTML-Entities-Interpolate-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'HTML-Entities-Interpolate',
	NAME      => 'HTML::Entities::Interpolate',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Capture::Tiny'		=> 0.44,
		'HTML::Entities'	=> 3.69,
		'strict'			=> 0,
		'Tie::Function'		=> 0.02,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'File::Slurper'		=> 0.009,
		'File::Spec'		=> 0,
		'Test::Pod'			=> 1.51,
		'Test::Simple'		=> 1.302052, # For Test::More.
	},
	VERSION_FROM => 'lib/HTML/Entities/Interpolate.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Entities-Interpolate',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/HTML-Entities-Interpolate.git',
				web		=> 'https://github.com/ronsavage/HTML-Entities-Interpolate',
			},
		},
	};
}

WriteMakefile(%params);
