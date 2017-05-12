use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'English names of nationalities',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Locale-Nationality-en-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME		=> 'Locale-Nationality-en',
	NAME			=> 'Locale::Nationality::en',
	LICENSE			=> 'perl',
	PL_FILES		=> {},
	TEST_REQUIRES	=>
	{
		'Test::Pod'		=> 1.51,
		'Test::Simple'	=> 1.302052, # For Test::More.
	},
	VERSION_FROM => 'lib/Locale/Nationality/en.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-Nationality-en',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/Locale-Nationality-en.git',
				web  => 'https://github.com/ronsavage/Locale-Nationality-en',
			},
		},
	};
}

WriteMakefile(%params);
