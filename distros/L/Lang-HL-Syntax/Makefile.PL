use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lang::HL::Syntax',
    VERSION_FROM      => 'lib/Lang/HL/Syntax.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Lang/HL/Syntax.pm', # retrieve abstract from module
    AUTHOR            => 'Rajkumar Reddy',
    EXE_FILES         => ['script/hle'],
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
