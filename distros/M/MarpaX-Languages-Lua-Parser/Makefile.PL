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
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'A Lua parser',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MarpaX-Languages-Lua-Parser*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'MarpaX-Languages-Lua-Parser',
	NAME		=> 'MarpaX::Languages::Lua::Parser',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Data::RenderAsTree'	=> 1.03,
		'Data::Section::Simple'	=> 0.07,
		'File::Spec'			=> 3.40,
		'File::Temp'			=> 0.2304,
		'Getopt::Long'			=> 2.41,
		'Log::Handler'			=> 0.84,
		'Marpa::R2'				=> 3.000000,
		'Moo'					=> 2.000001,
		'open'					=> 0,
		'Path::Tiny'			=> 0.068,
		'Pod::Usage'			=> 1.63,
		'strict'				=> 0,
		'Types::Standard'		=> 1.000005,
		'warnings'				=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001014,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/MarpaX/Languages/Lua/Parser.pm',
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
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-Lua-Parser',
			license		=> 'http://www.perlfoundation.org/artistic_license_2_0',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/MarpaX-Languages-Lua-Parser.git',
				web		=> 'https://github.com/ronsavage/MarpaX-Languages-Lua-Parser',
			},
		},
	};
}

WriteMakefile(%params);
