use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::Random::SkewNormal',
    VERSION_FROM      => 'lib/Math/Random/SkewNormal.pm', # finds $VERSION
    LICENSE => 'perl',
    PREREQ_PM         => {
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/Random/SkewNormal.pm', # retrieve abstract from module
       AUTHOR         => 'Jiri Vaclavik <my name dot my surname at gmail dot com>') : ()),
);
