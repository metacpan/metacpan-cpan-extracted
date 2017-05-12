use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Calculus::NewtonRaphson',
    'VERSION_FROM'	=> 'NewtonRaphson.pm', # finds $VERSION
    'PREREQ_PM'		=> {Math::Calculus::Differentiate => 0.3,
				    Math::Calculus::Expression => 0.1},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'NewtonRaphson.pm', # retrieve abstract from module
       AUTHOR     => 'J. Worthington <jonathan@jwcs.net>') : ()),
);
