use ExtUtils::MakeMaker;

# ----------------
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Determine the infinitive form of a conjugated word',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Lingua-EN-Infinitive-*'
	},
	dist =>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME			=> 'Lingua-EN-Infinitive',
	MIN_PERL_VERSION	=> 5.006,
	NAME				=> 'Lingua::EN::Infinitive',
	PL_FILES			=> {},
	PREREQ_PM			=>
	{
		'Moo'				=> 2.003000,
		'strict'			=> 0,
		'Types::Standard'	=> 1.000005,
		'warnings'			=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001002,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/Lingua/EN/Infinitive.pm'
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
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-EN-Infinitive',
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Lingua-EN-Infinitive.git',
				web		=> 'https://github.com/ronsavage/Lingua-EN-Infinitive',
			},
		},
	};
}

WriteMakefile(%params);
