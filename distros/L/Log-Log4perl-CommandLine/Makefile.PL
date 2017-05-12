use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Log::Log4perl::CommandLine',
    VERSION_FROM      => 'lib/Log/Log4perl/CommandLine.pm',
    PREREQ_PM         => {Getopt::Long => 0, Log::Log4perl => 0},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Log/Log4perl/CommandLine.pm',
       AUTHOR         => 'Curt Tilmes <ctilmes@cpan.org>') : ()),
);
