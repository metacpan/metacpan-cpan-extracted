use 5.032000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DuckCurses',
    VERSION_FROM      => 'lib/DuckCurses.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { Curses => 1.37, Timer::Simple }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/DuckCurses.pm', # retrieve abstract from module
    AUTHOR            => 'Kobold Wizard Johan <koboldwiz@yahoo.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
