use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Log::Log4perl::DataDumper',
    VERSION_FROM      => 'lib/Log/Log4perl/DataDumper.pm', # finds $VERSION
    PREREQ_PM         => { Log::Log4perl => 0,
                           Data::Dumper => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Log/Log4perl/DataDumper.pm',
       AUTHOR         => 'Curt Tilmes <ctilmes@cpan.org>') : ()),
);
