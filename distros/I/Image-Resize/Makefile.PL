use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::Resize',
    'VERSION_FROM'	=> 'Resize.pm',
    'PREREQ_PM'		=> {GD => 0},
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Resize.pm', # retrieve abstract from module
       AUTHOR     => 'Sherzod B. Ruzmetov <sherzodr@handalak.com>') : ()),
);
