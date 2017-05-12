use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Project3D',
    'VERSION_FROM'	=> 'lib/Math/Project3D.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        Math::MatrixReal => 1.9,
        Test::More => 0.44,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Project3D.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
