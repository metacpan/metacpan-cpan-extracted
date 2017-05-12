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
		ABSTRACT => 'Parse the templates used in pack() and unpack()',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MarpaX-Languages-Perl-PackUnpack-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'MarpaX-Languages-Perl-PackUnpack',
	NAME      => 'MarpaX::Languages::Perl::PackUnpack',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Const::Exporter' => 'v0.2.3',
		'Marpa::R2'       => 2.096000,
		'Moo'             => 1.006000,
		'open'            => 0,
		'strict'          => 0,
		'Test::More'      => 1.001006,
#		'Test::Pod'       => 1.45, # Make it optional. See xt/author/pod.t
		'Tree'            => 1.05,
		'Try::Tiny'       => 0.09,
		'Types::Standard' => 1.000004,
		'utf8'            => 0,
		'warnings'        => 0,
	},
	VERSION_FROM => 'lib/MarpaX/Languages/Perl/PackUnpack.pm',
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
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-Perl-PackUnpack',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/MarpaX-Languages-Perl-PackUnpack.git',
				web  => 'https://github.com/ronsavage/MarpaX-Languages-Perl-PackUnpack',
			},
		},
	};
}

WriteMakefile(%params);
