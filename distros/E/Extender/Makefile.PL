use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Extender',
    VERSION_FROM => 'lib/Extender.pm',  # Path to your main module file
    AUTHOR       => 'OnEhIppY @ Domero Software <domerosoftware@gmail.com>',
    ABSTRACT     => 'Dynamically enhance Perl objects with additional methods from other modules or custom subroutines',
    LICENSE      => 'perl',  # License type
    PREREQ_PM    => {
        'Test::More' => 0.98,  # Example version requirement
        'Test::Exception' => 0,
        'IO::Scalar' =>0,
    },     # Additional dependencies, if any
    EXE_FILES    => ['example/Extender.pl'],  # List of executable scripts
    META_MERGE   => {
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/DomeroSoftware/Extender.git',
                web  => 'https://github.com/DomeroSoftware/Extender',
            },
        },
    },
);
