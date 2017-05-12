use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Deprecated. Use under the name MarpaX::Languages::Dash',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST MarpaX-Demo-StringParser-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'MarpaX-Demo-StringParser',
	NAME      => 'MarpaX::Demo::StringParser',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		Capture::Tiny    => 0.11,
		charnames        => 0,
		Config           => undef,
		Config::Tiny     => 2.14,
		Date::Simple     => 3.03,
		File::Basename   => 2.78,
		File::Copy       => 2.21,
		File::HomeDir    => 0.99,
		File::Slurp      => 9999.19,
		File::Spec       => 3.33,
		Getopt::Long     => 2.38,
		GraphViz2        => 2.33,
		HTML::Entities::Interpolate => 1.04,
		Log::Handler     => 0.82,
		Marpa::R2        => 2.096000,
		Moo              => 1.002000,
		open             => 0,
		Path::Tiny       => 0.025,
		Pod::Usage       => 1.36,
		Set::Array       => 0.23,
		strict           => 0,
		Test::More       => 0.94,
#		Test::Pod        => 1.45, # Make it optional. See xt/author/pod.t.
		Text::CSV        => 1.32,
		Text::CSV::Slurp => 1.01,
		Text::Xslate     => 1.4001,
		Tree::DAG_Node   => 1.24,
		Try::Tiny        => 0.09,
		Types::Standard  => 1.000004,
		utf8             => 0,
		warnings         => 0,
	},
	VERSION_FROM => 'lib/MarpaX/Demo/StringParser.pm',
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
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Demo-StringParser',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/MarpaX-Demo-StringParser.git',
				web  => 'https://github.com/ronsavage/MarpaX-Demo-StringParser',
			},
		},
	};
}

WriteMakefile(%params);
