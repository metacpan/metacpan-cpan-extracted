use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

# yum install libaio-devel
# apk install libaio-dev

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'File::Open::NoCache::ReadOnly',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/File/Open/NoCache/ReadOnly.pm',
	ABSTRACT_FROM	   => 'lib/File/Open/NoCache/ReadOnly.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'autodie' => 0,
		'File::Temp' => 0,
		'IPC::System::Simple' => 0,
		'Test::DescribeMe' => 0,
		'Test::Exception' => 0.42,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Script' => 1.12,
		'Test::Carp' => 0,
		# 'Test::CleanNamespaces' => 0,
		# 'Test::Kwalitee' => 0,
		'Test::Warn' => 0
	}, PREREQ_PM => {
		'Carp' => 0,
		'IO::AIO' => 0,
		'Params::Get' => 0,
		'Scalar::Util' => 0
	}, dist => $dist,
	clean		=> { FILES => 'File-Open-NoCache-ReadOnly-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/File-Open-NoCache-ReadOnly.git',
				web => 'https://github.com/nigelhorne/File-Open-NoCache-ReadOnly',
				repository => 'https://github.com/nigelhorne/File-Open-NoCache-ReadOnly',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-Open-NoCache-ReadOnly',
				# mailto => 'bug-File-Open-NoCache-ReadOnly@rt.cpan.org'
				web => 'https://github.com/nigelhorne/File-Open-NoCache-ReadOnly/issues',
				url => 'https://github.com/nigelhorne/File-Open-NoCache-ReadOnly/issues',
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
