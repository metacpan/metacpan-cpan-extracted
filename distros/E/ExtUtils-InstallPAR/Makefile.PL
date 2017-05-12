use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ExtUtils::InstallPAR',
    VERSION_FROM      => 'lib/ExtUtils/InstallPAR.pm', # finds $VERSION
    PREREQ_PM         => {
      'PAR::Dist' => '0.40',
#      'ExtUtils::InferConfig' => '1.02',
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ExtUtils/InstallPAR.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : (),
       LICENSE => 'perl'),
);
