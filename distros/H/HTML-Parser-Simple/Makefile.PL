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
		ABSTRACT => 'Parse nice HTML files without needing a compiler',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST HTML-Parser-Simple-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'HTML-Parser-Simple',
	NAME      => 'HTML::Parser::Simple',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'File::Spec'   => 0,
		'lib'          => 0,
		'Moo'          => 1.003001,
		'strict'       => 0,
		'Test::More'   => 0,
#		'Test::Pod'    => 1.45, # Make it optional. See t/pod.t
		'Tree::Simple' => 0,
		'warnings'     => 0,
	},
	VERSION_FROM => 'lib/HTML/Parser/Simple.pm',
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
		resources   =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Parser-Simple',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/HTML-Parser-Simple.git',
				web  => 'https://github.com/ronsavage/HTML-Parser-Simple',
			},
		},
	};
}

WriteMakefile(%params);
