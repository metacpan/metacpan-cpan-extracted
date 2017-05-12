use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'HTTP::Request::Form',
    DISTNAME	=> 'HTTP-Request-Form',
    VERSION_FROM => 'Form.pm', # finds $VERSION
    PREREQ_PM	=> {
    	'HTTP::Request::Common' => 0,
	'URI::URL' => 0,
	'LWP::UserAgent' => 0,
	'HTML::TreeBuilder' => 0,
    },
    dist	=> { 
        PREOP => 'pod2text Form.pm >README',
        COMPRESS => 'gzip -9f', 
	SUFFIX => 'gz', 
    },
);
