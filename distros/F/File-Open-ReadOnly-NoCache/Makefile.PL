use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
	NAME		=> 'File::Open::ReadOnly::NoCache',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/File/Open/ReadOnly/NoCache.pm',
	ABSTRACT_FROM	   => 'lib/File/Open/ReadOnly/NoCache.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'autodie' => 0,
		'IPC::System::Simple' => 0,
		'Test::Exception' => 0.42,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::Script' => 1.12,
		'Test::CleanNamespaces' => 0,
		# 'Test::Kwalitee' => 0,
		'Test::Warn' => 0,
	},
	PREREQ_PM => {
		'Carp' => 0,
		'IO::AIO' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'File-Open-ReadOnly-NoCache-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/File-Open-ReadOnly-NoCache.git',
				web => 'https://github.com/nigelhorne/File-Open-ReadOnly-NoCache',
				repository => 'https://github.com/nigelhorne/File-Open-ReadOnly-NoCache',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-Open-ReadOnly-NoCache',
				# mailto => 'bug-File-Open-ReadOnly-NoCache@rt.cpan.org'
				web => 'https://github.com/nigelhorne/File-Open-ReadOnly-NoCache/issues',
				url => 'https://github.com/nigelhorne/File-Open-ReadOnly-NoCache/issues',
			}
		
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
