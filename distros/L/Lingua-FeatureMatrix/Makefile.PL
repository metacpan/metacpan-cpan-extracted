use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'		=> 'Lingua::FeatureMatrix',
	      'VERSION_FROM'	=> 'FeatureMatrix.pm', # finds $VERSION
	      'PREREQ_PM'		=> {Class::MethodMaker => 1.06,
					    Graph => 0.201},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'FeatureMatrix.pm', # retrieve abstract from module
       AUTHOR     => 'Jeremy Kahn <kahn@cpan.org>') : ()),
);
