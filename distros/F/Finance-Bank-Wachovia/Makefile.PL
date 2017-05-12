use 5.6.1;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Finance::Bank::Wachovia',
    EXE_FILES		 => [ 'scripts/wachovia.pl', 'scripts/wachovia_summary.pl' ],
    VERSION_FROM      => 'lib/Finance/Bank/Wachovia.pm', # finds $VERSION
    PREREQ_PM         => { 
    		'WWW::Mechanize' => 0, 
    		'HTTP::Cookies' => 0, 
    		'Test::More' => 0 ,
    		'Crypt::CBC' => 0,	
    		'Crypt::DES_PP' => 0,
    	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Finance/Bank/Wachovia.pm', # retrieve abstract from module
       AUTHOR         => 'Jim <jg.perl@thegarvin.com>') : ()),
);
