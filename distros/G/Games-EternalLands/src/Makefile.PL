use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::EternalLands::MapHelper',
    VERSION           => '0.04',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => 'bheap.o MapHelper.o', # link all the C files too
);
