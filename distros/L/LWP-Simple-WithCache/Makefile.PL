use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LWP::Simple::WithCache',
    VERSION_FROM      => 'lib/LWP/Simple/WithCache.pm', # finds $VERSION
    PREREQ_PM         => {
	'LWP::Simple'               => 0,
	'LWP::UserAgent::WithCache' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LWP/Simple/WithCache.pm', # retrieve abstract from module
       AUTHOR         => 'Yen-Ming Lee <leeym@leeym.com>') : ()),
);
