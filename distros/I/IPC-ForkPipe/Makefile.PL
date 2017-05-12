use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::ForkPipe',
    VERSION_FROM      => 'lib/IPC/ForkPipe.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    LICENSE           => 'perl',
    dist              => { COMPRESS=>'gzip -9f', EXT=>'gz'},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPC/ForkPipe.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn <gwyn-at-cpan.org>'


    ) : ()),
);
