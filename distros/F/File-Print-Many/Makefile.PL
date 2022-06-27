use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use File::Spec 3.4;

WriteMakefile(
	NAME		=> 'File::Print::Many',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/File/Print/Many.pm',
	ABSTRACT_FROM	=> 'lib/File/Print/Many.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'File::Path' => 2.15,
		'File::Spec' => 0,
		'Test::Carp' => 0,
		'Test::Exception' => 0.42,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::CleanNamespaces' => 0,
		'Test::Requires' => 0,
		'Test::TempDir::Tiny' => 0,
		# 'Test::Kwalitee' => 0,
		'autodie' => 0,
		'Test::Warn' => 0,
	},
	PREREQ_PM => {
		'Carp' => 0,
		# 'Tie::Handle' => 0,
		'namespace::autoclean' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'File-Print-Many-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/File-Print-Many.git',
				web => 'https://github.com/nigelhorne/File-Print-Many',
			}, bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-Print-Many',
				mailto => 'bug-File-Print-Many@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
