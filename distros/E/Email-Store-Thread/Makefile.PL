use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Email::Store::Thread',
    VERSION_FROM      => 'lib/Email/Store/Thread.pm', # finds $VERSION
    PREREQ_PM         => {
        Email::Folder => 0,
        Mail::Thread => 2.5,
        Email::Store => 0,

    }, # e.g., Module::Name => 1.1
);
print "Don't forget you're going to have to run Email::Thread->setup
again to create the new table.\n";
