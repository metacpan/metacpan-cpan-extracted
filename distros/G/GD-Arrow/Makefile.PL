
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'GD::Arrow',
    VERSION_FROM      => 'lib/GD/Arrow.pm', # finds $VERSION
    PREREQ_PM         => { GD => 0, Carp => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GD/Arrow.pm', # retrieve abstract from module
       AUTHOR         => 'Todd Caine <tcaine@pobox.com>') : ()),
);
