use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GlbDNS',
    VERSION_FROM      => 'lib/GlbDNS.pm', # finds $VERSION
    PREREQ_PM         => {
      'Working::Daemon' => 0.31,
      'Geo::IP' => 0,
      'Net::DNS' => 0,
      'LWP::Simple' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GlbDNS.pm', # retrieve abstract from module
       AUTHOR         => 'Artur Bergman <sky+cpan@crucially.net') : ()),
);
