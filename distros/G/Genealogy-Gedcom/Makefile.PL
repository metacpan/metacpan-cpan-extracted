use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'An OS-independent processor for GEDCOM data',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST Genealogy-Gedcom-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'Genealogy-Gedcom',
	NAME      => 'Genealogy::Gedcom',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'File::Slurper' => 0.008,
		'Genealogy::Gedcom::Date' => 2.06,
		'Getopt::Long' => 0,
		'Log::Handler' => 0.84,
		'Moo' => 2.000002,
		'Pod::Usage' => 0,
		'Set::Array' => 0.30,
		'strict' => 0,
		'Types::Standard' => 1.000005,
		'warnings' => 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Pod'		=> 1.51,
		'Test::Simple'	=> 1.302052, # For Test::More.
	},
	VERSION_FROM => 'lib/Genealogy/Gedcom.pm',
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
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy-Gedcom',
			},
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/Genealogy-Gedcom.git',
				web		=> 'https://github.com/ronsavage/Genealogy-Gedcom',
			},
		},
	};
}

WriteMakefile(%params);
