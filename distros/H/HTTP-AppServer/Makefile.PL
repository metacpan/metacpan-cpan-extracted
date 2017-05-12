use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTTP::AppServer',
    VERSION_FROM      => 'lib/HTTP/AppServer.pm', # finds $VERSION
    PREREQ_PM         => {  # e.g., Module::Name => 1.1
    	'Data::Dumper' => 0,
    	'HTTP::Server::Simple::CGI' => 0,
    	'DBI' => 0,
    	'IO::File' => 0,
    	'JSON' => 0,
    	'Path::Trim' => 0,
    	'MIME::Base64' => 0,
    	'Data::UUID' => 0,
    },
    PMLIBDIRS 		  => [ 'lib', $BASEEXT ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTTP/AppServer.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Kirchner <tom@tkirchner.com>') : ()),
);
