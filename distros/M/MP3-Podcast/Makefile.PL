use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'		=> 'MP3::Podcast',
	      'VERSION_FROM'	=> 'lib/MP3/Podcast.pm', # finds $VERSION
	      'PREREQ_PM'	=> {XML::RSS => '1.05',
				    MP3::Info => '1.13',
				    URI => 0}, # e.g., Module::Name => 1.1
	      ($] >= 5.006 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'lib/MP3/Podcast.pm', # retrieve abstract from module
		AUTHOR     => 'Juan Julian Merelo Guervos <jmerelo@geneura.ugr.es>') : ()),
);
