use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mail::Send::Loop',
    VERSION_FROM      => 'lib/Mail/Send/Loop.pm', # finds $VERSION
    PREREQ_PM         => {
    	LWP::UserAgent	=> 5,
    	MIME::Lite		=> 3
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mail/Send/Loop.pm', # retrieve abstract from module
       AUTHOR         => 'Jing Kang <kxj@hotmail.com>') : ()),
);
