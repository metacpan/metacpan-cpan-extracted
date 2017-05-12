use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IETF::ACE',
    LICENSE           => 'perl_5',
    VERSION_FROM      => 'lib/IETF/ACE.pm', # finds $VERSION
    PREREQ_PM         => {
                           Unicode::String => 0,
                           MIME::Base64 => 0,
                         },
    TEST_REQUIRES     => {
                           Test::More => 0,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IETF/ACE.pm', # retrieve abstract from module
       AUTHOR         => 'James Briggs <james.briggs@yahoo.com>') : ()),
);
