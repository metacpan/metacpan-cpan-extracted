use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::Derivative_XS',
    VERSION_FROM      => 'lib/Math/Derivative_XS.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/Math/Derivative_XS.pm', # retrieve abstract from module
    AUTHOR         => 'Mark Aufflick <mark@pumptheory.com>',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-Wall -Werror', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    BUILD_REQUIRES    => {
        'Test::More' => 0,
        'YAML::XS'   => 0,
    },
    PREREQ_PM         => {
        'Math::Derivative' => 0,
    },
);
