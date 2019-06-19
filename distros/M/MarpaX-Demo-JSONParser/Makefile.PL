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
		ABSTRACT => 'A JSON parser with a choice of grammars',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MarpaX-Demo-JSONParser-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME			=> 'MarpaX-Demo-JSONParser',
	MIN_PERL_VERSION	=> 5.014000,
	NAME				=> 'MarpaX::Demo::JSONParser',
	PL_FILES			=> {},
	PREREQ_PM			=>
	{
		'File::Basename'	=> 2.82,
		'File::Slurper'		=> 0.009,
		'Marpa::R2'			=> 3.000000,
		'MarpaX::Simple'	=> 0.06,
		'Moo'				=> 2.003000,
		'Path::Tiny'		=> 0.098,
		'strict'			=> 0,
		'Try::Tiny'			=> 0.27,
		'Types::Standard'	=> 1.000005,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/MarpaX/Demo/JSONParser.pm',
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
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Demo-JSONParser',
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/MarpaX-Demo-JSONParser.git',
				web		=> 'https://github.com/ronsavage/MarpaX-Demo-JSONParser',
			},
		},
	};
}

WriteMakefile(%params);
