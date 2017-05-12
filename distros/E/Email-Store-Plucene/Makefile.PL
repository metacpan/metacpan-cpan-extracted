use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Email::Store::Plucene',
    VERSION_FROM      => 'Plucene.pm', # finds $VERSION
    PREREQ_PM         => {
        Plucene::Simple => 1,
        Email::Store => 0,
        Email::Folder => 0, # Just for testing, but you know you want it
    }, # e.g., Module::Name => 1.1
);
