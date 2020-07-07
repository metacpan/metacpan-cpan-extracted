use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              	=> 'Linux::realtimed',
    AUTHOR            	=> 'Anselmo Canfora <acanfora@cpan.org>',
	LICENSE				=> 'perl_5',
	MIN_PERL_VERSION	=> 5.010,
    VERSION_FROM      	=> 'lib/Linux/realtimed.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    ABSTRACT_FROM     	=> 'lib/Linux/realtimed.pm', # retrieve abstract from module
	EXE_FILES			=> [
		'bin/realtimed'
	],
    PREREQ_PM         	=> {
		'Linux::Inotify2'	=> 0,
		'Sys::Syslog'		=> 0,
		'Time::HiRes'		=> 0,
		Socket				=> 0,
		JSON				=> 0,
		EV					=> 0,
	},
	META_MERGE			=> {
		"meta-spec"			=> { version => 2 },
		resources			=> {
			repository			=> {
				type => 'git',
				url => 'https://github.com/ANSI-C/realtimed.git',
				web => 'https://github.com/ANSI-C/realtimed',
			},
		},

	},
);
