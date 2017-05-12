use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MIME::Lite::HTML',
    'VERSION_FROM'	=> 'HTML.pm', # finds $VERSION
    'PREREQ_PM'		=> {	
	    			MIME::Lite      => 1.0,
				LWP::UserAgent  => 0,
				HTML::LinkExtor => 0,
				URI::URL	=> 0,
				Test::More	=> 0
			}, # e.g., Module::Name => 1.1
     ($] ge '5.005') ? 
		  (
		   'AUTHOR' => 'Alain BARBET (alian@cpan.org)',
		   'ABSTRACT' => 'Provide routine to transform a HTML page '.
		                 'in a MIME-Lite mail') : ()
		 );
