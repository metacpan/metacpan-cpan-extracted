# tag: Perl MakeMaker info file

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'JOAP',
    'VERSION_FROM'	=> 'JOAP.pm',
    'PREREQ_PM'		=> {Net::Jabber => 1.28,
                            Class::Data::Inheritable => 0.02,
                            Symbol => 1.04,
                            Error => 0.15},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'JOAP.pm', # retrieve abstract from module
       AUTHOR     => 'Evan Prodromou <evan\@prodromou.san-francisco.ca.us>') : ()),
);
