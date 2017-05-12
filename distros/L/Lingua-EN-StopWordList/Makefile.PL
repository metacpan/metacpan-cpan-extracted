use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'A sorted list of English stop words',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Lingua-EN-StopWordList-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Lingua-EN-StopWordList',
	NAME      => 'Lingua::EN::StopWordList',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'strict' => 1.04,
		'Test::More' => 1.001014,
		'Test::Pod' => 1.48,
		'warnings' => 1.12,
	},
	VERSION_FROM => 'lib/Lingua/EN/StopWordList.pm',
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
			'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-EN-StopWordList',
			'license'    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				'type' => 'git',
				'url'  => 'https://github.com/ronsavage/Lingua-EN-StopWordList.git',
				'web'  => 'https://github.com/ronsavage/Lingua-EN-StopWordList',
			},
		},
	};
}

WriteMakefile(%params);
