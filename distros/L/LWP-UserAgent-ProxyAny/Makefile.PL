use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'			=> 'LWP::UserAgent::ProxyAny',
	'VERSION_FROM'	=> 'ProxyAny.pm', # finds $VERSION
	'NO_META'   	=> 1,
	'PREREQ_PM'		=> {
			LWP,
		}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	  (ABSTRACT_FROM => 'ProxyAny.pm', # retrieve abstract from module
	   AUTHOR     => 'Qing-Jie Zhou <qjzhou@hotmail.com>') : ()),
);