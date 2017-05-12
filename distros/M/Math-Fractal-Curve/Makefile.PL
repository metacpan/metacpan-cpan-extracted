use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Fractal::Curve',
    'VERSION_FROM'	=> 'lib/Math/Fractal/Curve.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Imager => 0,
	    Test::More => 0,
	    Exporter => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Fractal/Curve.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <fractal-module at steffen-mueller dot net>') : ()),
);
