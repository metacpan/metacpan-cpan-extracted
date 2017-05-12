use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::Embroidery',
    'VERSION_FROM'	=> 'lib/Image/Embroidery.pm', # finds $VERSION
    'PREREQ_PM'		=> {Bit::Vector => '6.3'}, # e.g., Module::Name => 1.1
    'LICENSE'           => 'perl',
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Image/Embroidery.pm', # retrieve abstract from module
       AUTHOR     => 'Kirk Baucom <kbaucom@schizoid.com>') : ()),
);
