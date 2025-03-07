use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		 => 'Log::YetAnother',
	VERSION_FROM => 'lib/Log/YetAnother.pm', # finds $VERSION
	AUTHOR	 => 'Nigel Horne <njh@nigelhorne.com>',
	ABSTRACT	 => 'A flexible logging class for Perl',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM	=> {
		'Carp'		=> 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Params::Get' => 0,
		'Sys::Syslog' => 0,
		'Scalar::Util'=> 0,
	},
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::More' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'File::Temp' => 0,
	},
	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Log-YetAnother.git',
				web => 'https://github.com/nigelhorne/Log-YetAnother',
			},
		},
	}, dist => $dist
);
