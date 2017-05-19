use 5.022002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::IN::TGC',
    VERSION_FROM      => 'lib/Lingua/IN/TGC.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Moose' => '2.00', 'Function::Parameters' => '2.00'}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Lingua/IN/TGC.pm', # retrieve abstract from module
    AUTHOR            => '',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
