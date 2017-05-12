use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Config;

WriteMakefile(
    NAME              => 'Mac::Spotlight::MDQuery',
    VERSION_FROM      => 'lib/Mac/Spotlight/MDQuery.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mac/Spotlight/MDQuery.pm', # retrieve abstract from module
       AUTHOR         => 'Adrian Hosey <alh@warhound.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    LDDLFLAGS         => $Config{lddlflags} . ' -framework CoreFoundation -framework CoreServices',
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
