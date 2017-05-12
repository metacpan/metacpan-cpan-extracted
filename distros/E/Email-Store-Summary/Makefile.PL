use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Email::Store::Summary',
    VERSION_FROM      => 'Summary.pm', # finds $VERSION
    PREREQ_PM         => {
        Email::Store => 0,
        Text::Original => 0,
    }, # e.g., Module::Name => 1.1
);
