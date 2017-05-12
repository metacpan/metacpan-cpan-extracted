use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::Hack::Patch::x86_64',
    VERSION_FROM      => 'lib/Games/Hack/Patch/x86_64.pm', # finds $VERSION
    PREREQ_PM         => { },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Hack/Patch/x86_64.pm', # retrieve abstract from module
       AUTHOR         => 'Ph. Marek <pmarek@cpan.org>') : ()),
);
