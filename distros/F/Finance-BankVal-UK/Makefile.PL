use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::BankVal::UK',
    VERSION_FROM      => 'lib/Finance/BankVal/UK.pm', # finds $VERSION
    PREREQ_PM         => {LWP::UserAgent => 5.835, XML::Simple => 2.18, JSON => 2.21, Crypt::SSLeay => 0.57}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'A module for controlling REST web service calls to Unified Software\'s UK bank validation services', # retrieve abstract from module
       AUTHOR         => 'A. Evans <support@unifiedsoftware.co.uk>') : ()),
);
