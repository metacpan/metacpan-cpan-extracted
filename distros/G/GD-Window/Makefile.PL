use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GD::Window',
    VERSION_FROM      => 'lib/GD/Window.pm', # finds $VERSION
    PREREQ_PM         => {GD => 2.32}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GD/Window.pm', # retrieve abstract from module
       AUTHOR         => 'Edward Funnekotter <efunneko+cpan@gmail.com>') : ()),
);
