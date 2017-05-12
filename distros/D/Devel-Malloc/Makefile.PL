use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Devel::Malloc',
    VERSION_FROM      => 'lib/Devel/Malloc.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'lib/Devel/Malloc.pm', # retrieve abstract from module
       AUTHOR         => 'Yury Kotlyarov') : ()),
    LIBS              => [''], # e.g., '-lm'
    CCFLAGS           => '-march=i686',
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
