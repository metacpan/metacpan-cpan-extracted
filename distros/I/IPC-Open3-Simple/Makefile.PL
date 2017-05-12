use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::Open3::Simple',
    VERSION_FROM      => 'lib/IPC/Open3/Simple.pm', # finds $VERSION
    PREREQ_PM         => {
        IPC::Open3 => 0,
        IO::Handle => 0,
	IO::Select => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPC/Open3/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Erwan Lemonnier <erwan@cpan.org>') : ()),
);
