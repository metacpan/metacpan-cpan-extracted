use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Gadabout',
    'VERSION_FROM'	=> 'Gadabout.pm',
    'PREREQ_PM'		=> { Image::Imlib2 => 0.03 }, 
    'LIBS'		=> [''], 
    'DEFINE'		=> '', 
    'INC'		=> '', 
);
