#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR		=> 'Ron Savage (ron@savage.net.au)',
		ABSTRACT	=> 'A plugin for Log::Handler using Log::Hander::Output::DBI',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Log-Handler-Plugin-DBI-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME	=> 'Log-Handler-Plugin-DBI',
	NAME		=> 'Log::Handler::Plugin::DBI',
	PL_FILES	=> {},
	PREREQ_PM	=>
	{
		'Carp'						=> 1.20,
		'Config::Plugin::Tiny'		=> 1.01,
		'DBD::SQLite'				=> 1.35,
		'DBIx::Admin::CreateTable'	=> 2.07,
		'DBIx::Connector'			=> 0.47,
		'File::HomeDir'				=> 1.004,
		'File::Spec'				=> 0,
		'Log::Handler::Output::DBI'	=> 0.11,
		'Moo'						=> 0.12,
		'strict'					=> 1.03,
		'Test::More'				=> 0.94,
		'Test::Pod'					=> 1.44,
		'vars'						=> 1.01,
		'warnings'					=> 1.03,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/Log/Handler/Plugin/DBI.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Handler-Plugin-DBI',
			},
			license    => 'http://dev.perl.org/licenses/',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/Log-Handler-Plugin-DBI.git',
				web  => 'https://github.com/ronsavage/Log-Handler-Plugin-DBI',
			},
		},
	};
}

WriteMakefile(%params);
