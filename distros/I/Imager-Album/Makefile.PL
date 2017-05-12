use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Imager::Album',
    'VERSION_FROM'	=> 'Album.pm', # finds $VERSION
    'PREREQ_PM'		=> {Imager => 0.41}, # e.g., Module::Name => 1.1
);
