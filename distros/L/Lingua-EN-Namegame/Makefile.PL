use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::EN::Namegame',
    'VERSION_FROM'	=> 'Namegame.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Carp' => 0 }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Namegame.pm', # retrieve abstract from module
       AUTHOR     => 'Tim Maher <tim@teachmeperl.com>') : ()),
);
