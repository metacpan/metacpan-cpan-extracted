use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Bank::AU::StGeorge',
    VERSION_FROM      => 'lib/Finance/Bank/AU/StGeorge.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/Bank/AU/StGeorge.pm', # retrieve abstract from module
       AUTHOR         => 'Iain Wade <iwade@optusnet.com.au>') : ()),
);
