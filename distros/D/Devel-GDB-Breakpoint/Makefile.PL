use 5.006000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Devel::GDB::Breakpoint',
    VERSION_FROM      => 'lib/Devel/GDB/Breakpoint.pm', # finds $VERSION
    BUILD_REQUIRES    => {'Test::More' => '0.88' },
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Devel/GDB/Breakpoint.pm', # retrieve abstract from module
       AUTHOR         => 'Matthew Horsfall (alh) <wolfsage@gmail.com>') : ()),
    OPTIMIZE          => '-g',
);
