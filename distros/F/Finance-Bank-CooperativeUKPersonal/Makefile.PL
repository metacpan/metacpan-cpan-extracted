use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Bank::CooperativeUKPersonal',
    VERSION           => '0.03',
    PREREQ_PM         => {  WWW::Mechanize => 1.64,
                            Crypt::SSLeay => 0.57,
                            File::Temp => 0.22,
                            HTML::DOM => 0.053},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/Bank/CooperativeUKPersonal.pm', # retrieve abstract from module
       AUTHOR         => 'Stephen Patterson <steve@patter.me.uk>') : ()),
);
