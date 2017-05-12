use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Devel::StealthDebug',
    'VERSION_FROM'	=> 'StealthDebug.pm', 
    'PREREQ_PM'		=> {Filter::Simple => 0, Test::More => 0, Carp => 0}, 
	dist			=> { 	COMPRESS	=> 'gzip',
							SUFFIX		=> '.gz' },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'StealthDebug.pm', # retrieve abstract from module
       AUTHOR     => 'Arnaud (Arhuman) ASSAD <arhuman@hotmail.com>') : ()),
);
