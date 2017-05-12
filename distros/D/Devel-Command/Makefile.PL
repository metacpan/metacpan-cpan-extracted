use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Devel::Command',
    VERSION_FROM      => 'lib/Devel/Command.pm', # finds $VERSION
    PREREQ_PM         => {
	                   'Module::Pluggable' => 0,
			   'Test::More' => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Joe McMahon <mcmahon@cpan.org>') : ()),
);
