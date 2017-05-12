use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MARC::Utils::MARC2MARC_in_JSON',
    VERSION_FROM      => 'lib/MARC/Utils/MARC2MARC_in_JSON.pm', # finds $VERSION
    PREREQ_PM         => {
        'MARC::Record' => 0,
        'Carp'         => 0,
        'Test::More'   => 0,
        'File::Spec'   => 0,
        'JSON'         => 2,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MARC/Utils/MARC2MARC_in_JSON.pm', # retrieve abstract from module
       AUTHOR         => 'Brad Baxter <bbaxter@cpan.org>') : ()),
);
