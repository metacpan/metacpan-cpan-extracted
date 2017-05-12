use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Symbolic::Custom::ErrorPropagation',
    'VERSION_FROM'	=> 'lib/Math/Symbolic/Custom/ErrorPropagation.pm',
    'PREREQ_PM'		=> {Math::Symbolic => 0.132,
    	Test::More => 0.44},
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Symbolic/Custom/ErrorPropagation.pm',
	AUTHOR     => 'Steffen Mueller <symbolic-module at steffen-mueller dot net>') : ()),
);
