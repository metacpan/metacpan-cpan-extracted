use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Approx::Symbolic',
    'VERSION_FROM'	=> 'lib/Math/Approx/Symbolic.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	    Math::Symbolic => 0.123,
	    Math::Approx => 0.200,
	    Test::More => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Approx/Symbolic.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <approx-symbolic-module at steffen-mueller dot net>') : ()),
);

