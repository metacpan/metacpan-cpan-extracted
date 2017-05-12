use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Project3D::Plot',
    'VERSION_FROM'	=> 'lib/Math/Project3D/Plot.pm', # finds $VERSION
    'LICENSE' => 'perl',
    'PREREQ_PM'		=> {
      Imager          => '0.41',
      Math::Project3D => '1.02',
      Test::More      => '0.44',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Project3D/Plot.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <project3d-module@steffen-mueller.net>') : ()),
);
