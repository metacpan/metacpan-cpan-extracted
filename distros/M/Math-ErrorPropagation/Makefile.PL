use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::ErrorPropagation',
    'VERSION_FROM'	=> 'ErrorPropagation.pm', # finds $VERSION
    'PREREQ_PM'		=> {Carp => 0, Test::Harness => 0, Test::More => 0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'ErrorPropagation.pm', # retrieve abstract from module
       AUTHOR     => 'Z. Sroczynski <zs@theorie.physik.uni-wuppertal.de>') : ()),
);
