use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Google::OAuth',
    VERSION_FROM      => 'lib/Google/OAuth.pm', # finds $VERSION
    PREREQ_PM         => {
		File::Copy => 2.13,
		NoSQL::PL2SQL => 1.21,
		LWP => 5.830,
		LWP::Protocol::https => 0,
		JSON => 2.57,
		}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Google/OAuth.pm', # retrieve abstract from module
       AUTHOR         => 'Jim Schueler <jim@tqis.com>') : ()),
);
