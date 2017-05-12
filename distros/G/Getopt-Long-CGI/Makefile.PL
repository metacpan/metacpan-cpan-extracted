use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Getopt::Long::CGI',
    VERSION_FROM      => 'lib/Getopt/Long/CGI.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {CGI => 0}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Getopt/Long/CGI.pm', # retrieve abstract from module
    AUTHOR            => 'Luke Ross <lross@>',
    LICENSE           => 'perl',
);
