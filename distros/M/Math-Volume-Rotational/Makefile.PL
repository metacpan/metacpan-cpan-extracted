use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Volume::Rotational',
    'VERSION_FROM'	=> 'lib/Math/Volume/Rotational.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	    Math::Integral::Romberg => 0.02,
	    Math::Symbolic => 0.129,
	    Test::More => 0.44,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Volume/Rotational.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <volume-module at steffen-mueller dot net>') : ()),
);
