use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

my $version = MM->parse_version('lib/File/pfopen.pm');

WriteMakefile(
	NAME		=> 'File::pfopen',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/File/pfopen.pm',
	ABSTRACT_FROM	=> 'lib/File/pfopen.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE' => 'gpl_2')
		: ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Config' => 0,
		'Errno' => 0,
		'File::Spec' => 0,
		'IPC::System::Simple' => 0,
		'Scalar::Util' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::TempDir::Tiny' => 0,
		'Test::Warnings' => 0,
	},
	PREREQ_PM => {
		'Carp' => 0,
		'Config' => 0,
		'File::Spec' => 0,
		'Exporter' => 0,
		'Scalar::Util' => 0,
	},
	dist => $dist,
	clean		=> { FILES => 'File-pfopen-*' },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		provides => {
			'File::pfopen' => {
				file => 'lib/File/pfopen.pm',
				version => $version,
			},
		},
		prereqs => {
			test => {
				# t/function.t and t/unit.t need these, and are skipped without them.
				#	They need newer versions of Perl than the module does
				recommends => {
					'Readonly' => 0,
					'Test::Memory::Cycle' => 0,
					'Test::Mockingbird' => '0.14',
					'Test::Returns' => '0.05',
				},
			},
			develop => {
				requires => {
					'Devel::Cover' => 0,
					'Perl::Critic' => 0,
					'Pod::Coverage' => '0.18',
					'Test::CheckManifest' => '0.9',
					'Test::Distribution' => 0,
					'Test::EOF' => 0,
					'Test::EOL' => 0,
					'Test::Group' => 0,
					'Test::Perl::Critic' => 0,
					'Test::Pod' => '1.22',
					'Test::Pod::Coverage' => '1.08',
					'Test::Pod::LinkCheck' => 0,
					'Test::Pod::No404s' => 0,
					'Test::Pod::Snippets' => 0,
					'Test::Pod::Spelling::CommonMistakes' => 0,
					'Test::Spelling' => 0,
					'Test::Spelling::Comment' => '0.002',
					'Test::Synopsis' => 0,
					'Test::Vars' => 0,
				},
			},
		},
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/File-pfopen.git',
				web => 'https://github.com/nigelhorne/File-pfopen',
			},
			bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-pfopen',
				mailto => 'bug-File-pfopen@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
