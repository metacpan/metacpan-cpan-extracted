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
		ABSTRACT => 'Check, Add and Remove BOMs',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST File-BOM-Utils-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'File-BOM-Utils',
	EXE_FILES => ['bin/bommer.pl'],
	NAME      => 'File::BOM::Utils',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'File::Slurper' => 0.008,
		'File::Spec' => 0,
		'Getopt::Long' => 0,
		'Moo' => 1.007000,
		'Pod::Usage' => 0,
		'strict' => 0,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'Types::Standard' => 1.000005,
		'utf8' => 0,
		'warnings' => 0,
	},
	VERSION_FROM => 'lib/File/BOM/Utils.pm',
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
		'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-BOM-Utils',
		'license' => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
		'type' => 'git',
		'url' => 'https://github.com/ronsavage/File-BOM-Utils.git',
		'web' => 'https://github.com/ronsavage/File-BOM-Utils',
			},
		},
	};
}

WriteMakefile(%params);
