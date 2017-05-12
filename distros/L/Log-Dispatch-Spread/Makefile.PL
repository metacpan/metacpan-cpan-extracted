use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "\n";
print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
print "NOTE: You must have a Spread server instance up and running on\n";
print "4803\@localhost in order for tests to work properly. If you do not,\n";
print "the module will compile and install successfully, but the tests\n";
print "will fail.\n";
print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";

WriteMakefile(
    NAME              => 'Log::Dispatch::Spread',
    VERSION_FROM      => 'lib/Log/Dispatch/Spread.pm', # finds $VERSION
    PREREQ_PM         => { Spread => 0, Log::Dispatch => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Log/Dispatch/Spread.pm', # retrieve abstract from module
       AUTHOR         => 'Brian Thomas <brian.thomas@gmail.com>') : ()),
);
