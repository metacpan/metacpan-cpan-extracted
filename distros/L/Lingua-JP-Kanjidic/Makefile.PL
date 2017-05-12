use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::JP::Kanjidic',
    VERSION_FROM      => 'lib/Lingua/JP/Kanjidic.pm', # finds $VERSION
    PREREQ_PM         => {
        Tie::File => 0,
        Encode::JP => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/JP/Kanjidic.pm', # retrieve abstract from module
       AUTHOR         => 'Simon Cozens <simon@cpan.org>') : ()),
);
