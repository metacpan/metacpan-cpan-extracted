use 5.024001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LibreDTE::SDK',
    VERSION_FROM      => 'lib/LibreDTE/SDK.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { 'REST::Client' => 88, 'JSON' => 2.9 }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/LibreDTE/SDK.pm', # retrieve abstract from module
    AUTHOR            => 'Esteban De La Fuente Rubio, DeLaF <esteban[at]sasco.cl>',
    LICENSE           => 'lgpl', # http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
