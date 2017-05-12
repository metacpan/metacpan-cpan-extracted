use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::LogRand',
    'VERSION_FROM'	=> 'lib/Math/LogRand.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    		"Test::More" => 0.98,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/LogRand.pm', # retrieve abstract from module
       AUTHOR         => 'Lee Goddard <lgoddard-at-cpan-dot-org>') : ()),
);
