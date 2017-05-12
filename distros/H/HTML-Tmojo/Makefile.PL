use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'HTML::Tmojo',
    'VERSION_FROM'	=> 'lib/HTML/Tmojo.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/HTML/Tmojo.pm', # retrieve abstract from module
       AUTHOR     => 'Will Conant <will@willconant.com>') : ()),
);
