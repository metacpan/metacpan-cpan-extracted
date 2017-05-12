use 5.011002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Devel::GDB::Parser::Breakpoint',
    VERSION_FROM      => 'lib/Devel/GDB/Parser/Breakpoint.pm', # finds $VERSION
    BUILD_REQUIRES    => {'Test::More' => '0.88' },
    PREREQ_PM         => {
        'Parse::Keyword' => '0.06',
        'Devel::GDB::Breakpoint' => '0.02',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Devel/GDB/Parser/Breakpoint.pm', # retrieve abstract from module
       AUTHOR         => 'Matthew Horsfall (alh) <wolfsage@gmail.com>') : ()),
);
