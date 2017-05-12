use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Devel::Carnivore',
    'VERSION_FROM'	=> 'Carnivore.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	Attribute::Handlers => 0.77,
    	Test::Simple        => 0.45,	
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Carnivore.pm', # retrieve abstract from module
       AUTHOR        => 'Malte Ubl <malteubl@gmx.de>') : ()),
);
