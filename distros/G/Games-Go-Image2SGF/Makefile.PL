use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Games::Go::Image2SGF',
    'VERSION_FROM'	=> 'Image2SGF.pm', # finds $VERSION
    'AUTHOR'        => 'Chris Ball <chris@cpan.org>', 
    'PREREQ_PM'		=> { Imager => 0 }
);
