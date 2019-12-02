use 5.005000;
use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME              => 'LWP::UserAgent::Cached',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/LWP/UserAgent/Cached.pm', # finds $VERSION
	PREREQ_PM         => { 'LWP::UserAgent' => 0 }, # e.g., Module::Name => 1.1
	BUILD_REQUIRES    => {
		'File::Temp' => 0,
		'Test::More' => 0.88,
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-LWP-UserAgent-Cached'},
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	(ABSTRACT_FROM  => 'lib/LWP/UserAgent/Cached.pm', # retrieve abstract from module
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
