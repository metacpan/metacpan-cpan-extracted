use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'GraphViz::DBI',
    'VERSION_FROM'	=> 'DBI.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	GraphViz => 0,
    },
);
