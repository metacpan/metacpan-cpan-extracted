use 5.010004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Libertatea::RSSreader',
    VERSION_FROM      => 'lib/Libertatea/RSSreader.pm', # finds $VERSION
    PREREQ_PM         => {
                    RSS::Feed => 0.56
        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Libertatea/RSSreader.pm', # retrieve abstract from module
       AUTHOR         => 'Mihai C <mhcrnl@localdomain>') : ()),
);
