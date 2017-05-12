use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MQdb',
    'VERSION_FROM'	=> 'lib/MQdb.pm', # finds $VERSION
    'AUTHOR'		=> 'Jessica Severin <jessica.severin@gmail.com>',
    'PREREQ_PM'		=> {
	DBI			=> 1.51,
	DBD::mysql		=> 3.0005,
	DBD::SQLite		=> 1.14,
    },
);
