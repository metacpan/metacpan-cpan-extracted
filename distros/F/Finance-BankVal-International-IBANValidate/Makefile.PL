use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::BankVal::International::IBANValidate',
    VERSION_FROM      => 'lib/Finance/BankVal/International/IBANValidate.pm', # finds $VERSION
    PREREQ_PM         => {LWP::UserAgent => 5.835, XML::Simple => 2.18, JSON => 2.21, Crypt::SSLeay => 0.57}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'A module to handle REST web service calls to Unified Software\'s IBAN validation service',
       AUTHOR         => 'A. Evans <support@unifiedsoftware.co.uk>') : ()),
);
