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
		ABSTRACT => 'A collection of scripts using Marpa::R2',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MarpaX-Demo-StringParser-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'MarpaX-Demo-SampleScripts',
	NAME      => 'MarpaX::Demo::SampleScripts',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Capture::Tiny' => 0.25,
		'charnames' => 0,
		'Data::Dumper' => 2.145,
		'Data::Section' => 0.200006,
		'diagnostics' => 0,
		'File::Slurp' => 9999.19,
		'Marpa::R2' => 2.098000,
		'Marpa::R2::HTML' => 2.098000,
		'Moo' => 1.006001,
		'open' => 0,
		'perl' => 5.010,
		'POSIX' => 1.32,
		'strict' => 0,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'Try::Tiny' => 0.22,
		'Types::Standard' => 1.000004,
		'utf8' => 0,
		'warnings' => 0,
	},
	VERSION_FROM => 'lib/MarpaX/Demo/SampleScripts.pm',
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
		'version' => 2,
		},
		resources   =>
		{
		'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Demo-SampleScripts',
		'license' => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
		'type' => 'git',
		'url' => 'https://github.com/ronsavage/MarpaX-Demo-SampleScripts.git',
		'web' => 'https://github.com/ronsavage/MarpaX-Demo-SampleScripts',
			},
		},
	};
}

WriteMakefile(%params);
