use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::BankVal::UK',
    VERSION_FROM      => 'lib/Finance/BankVal/UK.pm', # finds $VERSION
    PREREQ_PM         => {LWP::UserAgent => 0, JSON => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'A module to handle REST web service calls to Unified Software\'s UK bank validation services', # retrieve abstract from module
       AUTHOR         => 'A. Evans <support@unifiedsoftware.co.uk>') : ()),
);
