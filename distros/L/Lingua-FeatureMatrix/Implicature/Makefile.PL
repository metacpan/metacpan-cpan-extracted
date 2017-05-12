use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::FeatureMatrix::Implicature',
    'VERSION_FROM'	=> 'Implicature.pm', # finds $VERSION
    'PREREQ_PM'		=> {Class::MethodMaker => 1.06},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Implicature.pm', # retrieve abstract from module
       AUTHOR     => 'Jeremy Kahn <kahn@cpan.org>') : ()),
);
