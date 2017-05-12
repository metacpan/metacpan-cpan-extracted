use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Dyns::Client',
    'VERSION_FROM'	=> 'lib/Dyns/Client.pm',
    'PREREQ_PM'		=> {
		'LWP::UserAgent' => 0,
		'HTTP::Request' => 0,
		'Sys::Hostname' => 0,
		'Socket' => 0,
		'CGI::Util' => 0
	}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'lib/Dyns/Client.pm', # retrieve abstract from module
       AUTHOR     => 'Johan Van den Brande <johan@vandenbrande.com>') : ()),
);
