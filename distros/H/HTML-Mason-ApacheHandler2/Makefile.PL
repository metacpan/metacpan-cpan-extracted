use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print <<"*EOF*";
    -------------------------------------------------------------
    HTML::Mason::ApacheHandler2 is an EXPERIMENTAL ALPHA RELEASE!
           Please install and use it only on a test system.
                          Aloha => Beau;
    -------------------------------------------------------------
*EOF*
    sleep 5;

WriteMakefile(
    NAME              => 'HTML::Mason::ApacheHandler2',
    VERSION_FROM      => 'lib/HTML/Mason/ApacheHandler2.pm', # finds $VERSION
    PREREQ_PM         => 
	      {
		  mod_perl => 1.9910,
		  'HTML::Mason' => 1.25,
		  'Apache::Request' => '2.02-dev',
		  'Apache::Cookie' => '2.02-dev',
	      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Mason/ApacheHandler2.pm', # retrieve abstract from module
       AUTHOR         => 'Beau E. Cox <mason@beaucox.com>') : ()),
);
