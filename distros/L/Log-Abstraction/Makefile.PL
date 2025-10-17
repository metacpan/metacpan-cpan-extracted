use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME	 => 'Log::Abstraction',
	ABSTRACT_FROM => 'lib/Log/Abstraction.pm',
	VERSION_FROM => 'lib/Log/Abstraction.pm', # finds $VERSION
	AUTHOR	 => 'Nigel Horne <njh@nigelhorne.com>',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM => {
		'Carp'	 => 0,
		'Config::Abstraction' => 0.36,
		'Data::Dumper' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Log::Log4perl' => 0,
		'Params::Get' => 0.13,
		'POSIX' => 0,
		'Readonly::Values::Syslog' => 0.03,
		'Return::Set' => 0,
		'Sys::Syslog' => 0.28,
		'Scalar::Util'=> 0
	},
	TEST_REQUIRES => {
		'File::Glob' => 0,	# scripts/generate_index
		'File::Slurp' => 0,
		'File::Spec' => 0,
		'File::stat' => 0,
		'File::Temp' => 0,
		'JSON::MaybeXS' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'IPC::System::Simple' => 0,
		'Test::DescribeMe' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
		'YAML::XS' => 0
	},
	dist => $dist,
	clean	 => {
		FILES => 'Log-Abstraction-*'
	}, META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Log::Abstraction',
			repository => {
				repository => 'https://github.com/nigelhorne/Log-Abstraction',
				type => 'git',
				url => 'git://github.com/nigelhorne/Log-Abstraction.git',
				web => 'https://github.com/nigelhorne/Log-Abstraction'
			}, bugtracker => {
				mailto => 'bug-Log-Abstraction@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Abstraction',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Abstraction',
				# url => 'https://github.com/nigelhorne/Log-Abstraction/issues',
				# web => 'https://github.com/nigelhorne/Log-Abstraction/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
