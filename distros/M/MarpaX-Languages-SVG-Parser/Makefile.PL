use strict;
use warnings;

use ExtUtils::MakeMaker;

require 5.014002; # For the utf8 stuff.

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'An SVG parser',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MarpaX-Languages-SVG-Parser*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'MarpaX-Languages-SVG-Parser',
	NAME      => 'MarpaX::Languages::SVG::Parser',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Capture::Tiny'			=> 0.22,
		'Config'				=> 0,
		'Config::Tiny'			=> 2.19,
		'Data::Section::Simple'	=> 0.05,
		'Date::Simple'			=> 3.03,
		'Encode'				=> 0,
		'File::Basename'		=> 2.82,
		'File::Copy'			=> 2.21,
		'File::HomeDir'			=> 1.00,
		'File::Slurper'			=> 0.009,
		'File::Spec'			=> 3.40,
		'File::Temp'			=> 0.2304,
		'Getopt::Long'			=> 2.41,
		'Log::Handler'			=> 0.79,
		'Marpa::R2'				=> 2.082000,
		'Moo'					=> 1.003001,
		'open'					=> 0,
		'Path::Tiny'			=> 0.034,
		'Pod::Usage'			=> 1.63,
		'Set::Array'			=> 0.30,
		'strict'				=> 0,
		'Text::CSV'				=> 0,
		'Text::Xslate'			=> 1.6002,
		'Types::Standard'		=> 0.026,
		'utf8'					=> 0,
		'warnings'				=> 0,
		'XML::Parser'			=> 2.44,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/MarpaX/Languages/SVG/Parser.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-SVG-Parser',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/MarpaX-Languages-SVG-Parser.git',
				web		=> 'https://github.com/ronsavage/MarpaX-Languages-SVG-Parser',
			},
		},
	};
}

WriteMakefile(%params);
