#use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HOI::Comprehensions',
    VERSION_FROM      => 'lib/HOI/Comprehensions.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    #PREREQ_PM         => { 'Inline::C' => 0.64 }, 
    ABSTRACT_FROM     => 'lib/HOI/Comprehensions.pm', # retrieve abstract from module
    AUTHOR            => 'withering <withering@cpan.org>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
