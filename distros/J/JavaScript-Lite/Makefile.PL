use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'JavaScript::Lite',
    VERSION_FROM      => 'lib/JavaScript/Lite.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More'        => 0.8,
        'Test::Exception'   => 0.27,        
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/JavaScript/Lite.pm', # retrieve abstract from module
       AUTHOR         => 'Tyler MacDonald <japh@crackerjack.net>') : ()),
    LIBS              => ['-ljs -lmozjs -lnspr4'], # e.g., '-lm'
    DEFINE            => '-Wall -Werror', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I/usr/include/mozjs', # e.g., '-I. -I/usr/include/other'
    LICENSE           => 'perl',
);


