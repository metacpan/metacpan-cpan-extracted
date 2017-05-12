use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Graphics::ColorUtils',
    VERSION_FROM      => 'lib/Graphics/ColorUtils.pm', # finds $VERSION
    PREREQ_PM         => { Carp }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Graphics/ColorUtils.pm', # retrieve abstract from module
       AUTHOR         => 'Philipp K. Janert <janert at ieee dot org>') : ()),
);
