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
		? ('LICENSE'=> 'gpl_2')
		: ()),
	PREREQ_PM => {
		'autodie' => 0,
		'Carp'	 => 0,
		'Config::Abstraction' => 0.40,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'File::Basename' => 0,
		# Params::Get (via Config::Abstraction) uses autodie qw(:all) but
		# doesn't declare IPC::System::Simple, which that needs
		'IPC::System::Simple' => 0,
		'JSON::PP' => 0,
		'Log::Log4perl' => 0,
		'Params::Get' => 0.15,
		'POSIX' => 0,
		'Readonly' => 0,
		'Readonly::Values::Syslog' => 0.04,
		'Return::Set' => 0.04,
		'Sys::Syslog' => 0.28,
		'Scalar::Util'=> 0,
		'Socket' => 0,
		'Sub::Private' => 0.05,
		'Time::HiRes' => 0,
		'Time::Local' => 0,
	},
	TEST_REQUIRES => {
		'Config' => 0,
		'Data::Dumper' => 0,
		'File::Path' => 0,
		'File::Spec' => 0,
		'File::Temp' => 0,
		'IPC::Open3' => 0,
		'POSIX' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0.10,
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
		prereqs => {
			develop => {
				requires => {
					'Devel::Cover' => 0,
					'Perl::Critic' => 0,
					'Pod::Coverage' => 0.18,
					'Test::Carp' => 0,
					'Test::CheckManifest' => 0.9,
					'Test::Compile' => 0,
					'Test::CPAN::Changes' => 0.4,
					'Test::EOF' => 0,
					'Test::EOL' => 0,
					'Test::Kwalitee' => 0,
					'Test::Pod' => 1.22,
					'Test::Pod::Coverage' => 1.08,
					'Test::Pod::Spelling::CommonMistakes' => 0,
					'Test::Spelling::Comment' => 0.002,
					'Test::Synopsis' => 0,
				},
			},
			runtime => {
				recommends => {
					'Log::Any' => 0,	# Log::Any::Adapter::Abstraction
					'Email::Simple' => 0,	# sendmail backend
					'Email::Sender::Simple' => 0,
					'Email::Sender::Transport::SMTP' => 0,
				},
			},
		}, resources => {
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
	MIN_PERL_VERSION	=> '5.014'	# Readonly::Values::Syslog needs v5.14
);
