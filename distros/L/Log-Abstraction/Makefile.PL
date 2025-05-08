use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		 => 'Log::Abstraction',
	VERSION_FROM => 'lib/Log/Abstraction.pm', # finds $VERSION
	AUTHOR	 => 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT	 => 'A flexible logging class for Perl',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM => {
		'Carp'	 => 0,
		'Config::Abstraction' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Log::Log4perl' => 0,
		'Params::Get' => 0.04,
		'Sys::Syslog' => 0,
		'Scalar::Util'=> 0
	},
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::More' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'File::Spec' => 0,
		'File::Temp' => 0,
		'YAML::XS' => 0
	},
	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Log-Abstraction.git',
				web => 'https://github.com/nigelhorne/Log-Abstraction',
			},
		},
	}, dist => $dist
);
