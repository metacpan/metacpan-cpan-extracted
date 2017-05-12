use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'A Marpa-based parser for the DASH language',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MarpaX-Languages-Dash-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'MarpaX-Languages-Dash',
	NAME      => 'MarpaX::Languages::Dash',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Capture::Tiny'					=> 0.44,
		'charnames'						=> 0,
		'Config'						=> undef,
		'Config::Tiny'					=> 2.23,
		'Date::Simple'					=> 3.03,
		'File::Basename'				=> 2.78,
		'File::Copy'					=> 2.21,
		'File::HomeDir'					=> 1.00,
		'File::Slurper'					=> 0.009,
		'File::Spec'					=> 3.33,
		'Getopt::Long'					=> 2.38,
		'GraphViz2'						=> 2.44,
		'HTML::Entities::Interpolate'	=> 1.10,
		'Log::Handler'					=> 0.88,
		'Marpa::R2'						=> 3.000000,
		'Moo'							=> 2.003000,
		'open'							=> 0,
		'Path::Tiny'					=> 0.098,
		'Pod::Usage'					=> 1.36,
		'Set::Array'					=> 0.30,
		'strict'						=> 0,
		'Text::CSV'						=> 1.33,
		'Text::Xslate'					=> 3.3.9,
		'Tree::DAG_Node'				=> 1.29,
		'Try::Tiny'						=> 0.27,
		'Types::Standard'				=> 1.000005,
		'utf8'							=> 0,
		'warnings'						=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::More'	=> 1.001014,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/MarpaX/Languages/Dash.pm',
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
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-Dash',
			license		=> 'http://opensource.org/licenses/Artistic-2.0',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/MarpaX-Languages-Dash.git',
				web		=> 'https://github.com/ronsavage/MarpaX-Languages-Dash',
			},
		},
	};
}

WriteMakefile(%params);
