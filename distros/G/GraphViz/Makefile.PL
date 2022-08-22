#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;

use Config;

use ExtUtils::MakeMaker;

# ----------------

if ($^O eq 'MSWin32') {
	require File::Which;
	if (!File::Which::which('dot'))
	{
		print "Please install Graphviz from http://www.graphviz.org/.\n";
		exit;
	}
} else {
	if (open my $fh, '|dot', )
	{
		close $fh;
	}
	else
	{
		print "Please install Graphviz from http://www.graphviz.org/.\n";
		exit;
	}
}

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Leon Brocard <acme@astray.com>',
		ABSTRACT => "Interface to AT&T's GraphViz. Deprecated. See GraphViz2",
	) : (),
	dist =>
	{
		'COMPRESS' => 'gzip -9f',
		'SUFFIX' => 'gz',
	},
	DISTNAME  => 'GraphViz',
	LICENSE   => 'artistic_2',
	NAME      => 'GraphViz',
	PREREQ_PM =>
	{
		'Carp'				=> 1.01,
		'Config'			=> 0,
		'File::Which'		=> 1.09,
		'Getopt::Long'		=> 2.34,
		'IO::Dir'			=> 1.04,
		'IO::File'			=> 1.10,
		'IPC::Run'			=> 0.6,
		'lib'				=> 0,
		'LWP::Simple'		=> 6.00,
		'Parse::RecDescent'	=> 1.965001,
		'perl'				=> 5.006,
		'Pod::Usage'		=> 1.16,
		'strict'			=> 0,
		'Time::HiRes'		=> 1.51,
		'vars'				=> 0,
		'warnings'			=> 0,
		'XML::Twig'			=> 3.52,
		'XML::XPath'		=> 1.13,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/GraphViz.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/GraphViz.git',
				web		=> 'https://github.com/ronsavage/GraphViz',
			},
		},
	};
}

WriteMakefile(%params);
