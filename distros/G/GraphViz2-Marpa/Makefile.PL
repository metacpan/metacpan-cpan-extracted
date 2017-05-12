#!/usr/bin/env perl

use strict;
use warnings;

use Config;

use ExtUtils::MakeMaker;

# -----------------------------------------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'A Marpa-based parser for Graphviz dot files',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST GraphViz2-Marpa-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'GraphViz2-Marpa',
	NAME      => 'GraphViz2::Marpa',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Algorithm::Diff'				=> 1.1903,
		'Capture::Tiny'					=> 0.44,
		'Config'						=> 0,
		'Config::Tiny'					=> 2.23,
		'Date::Format'					=> 2.24,
		'Date::Simple'					=> 3.03,
		'File::Basename'				=> 2.85,
		'File::Copy'					=> 0,
		'File::HomeDir'					=> 1.00,
		'File::Spec'					=> 3.62,
		'File::Temp'					=> 0.2304,
		'File::Which'					=> 1.21,
		'Getopt::Long'					=> 2.38,
		'HTML::Entities::Interpolate'	=> 1.10,
		'Log::Handler'					=> 0.88,
		'Marpa::R2'						=> 3.000000,
		'Moo'							=> 2.002004,
		'Path::Iterator::Rule'			=> 1.012,
		'Path::Tiny'					=> 0.096,
		'perl'							=> 5.010001,
		'Pod::Usage'					=> 1.36,
		'strict'						=> 0,
		'Text::Xslate'					=> 3.3.9,
		'Tree::DAG_Node'				=> 1.29,
		'Try::Tiny'						=> 0.27,
		'Types::Standard'				=> 1.000005,
		'warnings'						=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Pod'		=> 1.51,
		'Test::More'	=> 1.001002,
	},
	VERSION_FROM => 'lib/GraphViz2/Marpa.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2-Marpa',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/GraphViz2-Marpa.git',
				web		=> 'https://github.com/ronsavage/GraphViz2-Marpa',
			},
		},
	};
}

WriteMakefile(%params);
