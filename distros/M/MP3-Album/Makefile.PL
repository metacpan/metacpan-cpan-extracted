BEGIN {
 unshift @INC, "lib";
}

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MP3::Album',
    'VERSION_FROM'	=> 'Album.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    		MP3::Album::Track 		   => 0,
		MP3::Album::Layout 		   => 0,
		MP3::Album::Layout::Fetcher 	   => 0,
		MP3::Album::Layout::Fetcher::CDDB  => 0,
		'MP3::Album::Layout::Fetcher::Tag' => 0,
		File::Basename 			   => 0,
		File::Copy     			   => 0,
		MP3::Info 			   => 1.01,
		CDDB 				   => 1.08,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Album.pod', # retrieve abstract from module
       AUTHOR        => 'Bruno Tavares <bmavt@cpan.org>') : ()),
);
