use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Insolation',
    VERSION_FROM      => 'lib/Insolation.pm', # finds $VERSION
    PREREQ_PM         => {Math::Trig => 1.1}, # 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Insolation.pm', # retrieve abstract from module
       AUTHOR         => 'Travis Kent Beste <travis@tencorners.com>') : ()),
);
