use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Devel::Walk',
    VERSION_FROM      => 'lib/Devel/Walk.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                Storable => 3,
                IO::File => 1,
            },
    ABSTRACT_FROM     => 'lib/Devel/Walk.pm', # retrieve abstract from module
    AUTHOR            => 'Philip Gwyn <perl -at- pied.nu>',
    LICENSE           => 'perl',
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},
);
