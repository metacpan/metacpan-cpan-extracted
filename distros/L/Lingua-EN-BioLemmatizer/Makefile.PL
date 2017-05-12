use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::EN::BioLemmatizer',

    VERSION_FROM      => 'lib/Lingua/EN/BioLemmatizer.pm', # finds $VERSION

    PREREQ_PM         => {
            "Carp"              => 1.08,        # vers from v5.10
            "IPC::Open2"        => 1.02,        # vers from v5.10
            "IO::Handle"        => 1.27,        # vers from v5.10
            "Scalar::Util"      => 1.19,        # vers from v5.10
            "Errno"             => 1.1,         # vers from v5.10
            "Devel::Peek"       => 1.03,        # vers form v5.10
	    "Test::More"        => 0.96,
	    "Test::Exception"   => 0.31,
    }, 

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/EN/BioLemmatizer.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Christiansen <tchrist@perl.com>') : ()),


);
