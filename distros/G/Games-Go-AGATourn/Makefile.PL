use 5.002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Games::Go::AGATourn',
    VERSION_FROM      => 'AGATourn.pm',
    PREREQ_PM         => {
                          }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Module to help parsing American Go Association (AGA) tournament files',
       AUTHOR         => 'Reid Augustin <reid@netchip.com>') : ()),
);
