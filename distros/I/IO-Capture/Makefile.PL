use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME      	 => 'IO::Capture',
    VERSION_FROM => 'lib/IO/Capture.pm', # finds $VERSION
    PREREQ_PM 	 => {Carp => 0, Test::More => 0},
);

