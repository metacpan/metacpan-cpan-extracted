use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Geography::Countries::LatLong',
    'VERSION_FROM'	=> 'lib/Geography/Countries/LatLong.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Geography::Countries'	=> 0.1,
		'Test::More'			=> 0.1,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Geography/Countries/LatLong.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard -at- cpan -dot- org>') : ()),
);
