use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Parse GEDCOM dates in French r/German/Gregorian/Hebrew/Julian',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Genealogy-Gedcom-Date-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Genealogy-Gedcom-Date',
	NAME      => 'Genealogy::Gedcom::Date',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Config'				=> 0,
		'Data::Dumper::Concise'	=> 2.022,
		'Getopt::Long'			=> 0,
		'Log::Handler'			=> 0.88,
		'Marpa::R2'				=> 3.000000,
		'Moo'					=> 2.002004,
		'Pod::Usage'			=> 0,
		'strict'				=> 0,
		'Try::Tiny'				=> 0.24,
		'Types::Standard'		=> 1.000005,
		'utf8'					=> 0,
		'warnings'				=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Pod'		=> 1.51,
		'Test::More'	=> 1.302052,
	},
	VERSION_FROM => 'lib/Genealogy/Gedcom/Date.pm',
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
		resources   =>
		{
			bugtracker =>
			{
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Gedcom-Date',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Genealogy-Gedcom-Date.git',
				web		=> 'https://github.com/ronsavage/Genealogy-Gedcom-Date',
			},
		},
	};
}

WriteMakefile(%params);
