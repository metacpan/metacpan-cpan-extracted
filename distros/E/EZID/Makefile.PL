use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'EZID',
    VERSION_FROM      => 'lib/EZID.pm', # finds $VERSION
    PREREQ_PM         => {
        'Modern::Perl' => '1.20140107',
        'String::Random' => '0.22',
    },
    TEST_REQUIRES => {
        'Test::More' => '1.001006',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/EZID.pm', # retrieve abstract from module
       AUTHOR         => 'Julian <julian.maurice@biblibre.com>') : ()),
);
