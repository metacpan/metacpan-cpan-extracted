use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Linux::Input::Wiiuse',
    VERSION_FROM      => 'lib/Linux/Input/Wiiuse.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Linux/Input/Wiiuse.pm', # retrieve abstract from module
       AUTHOR         => 'Dusty Wilson <dusty@megagram.com>') : ()),
    LIBS              => ['-lwiiuse'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -Isrc/wiiuse_v0.12/src',
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
