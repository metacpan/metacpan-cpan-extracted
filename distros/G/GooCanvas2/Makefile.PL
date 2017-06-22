use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GooCanvas2',
    VERSION_FROM      => 'lib/GooCanvas2.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Test'        =>  0,
    			  'Gtk3'	=>  0, }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/GooCanvas2.pm', # retrieve abstract from module
    AUTHOR            => 'Maximilian Lika <Maximilian-Lika@gmx.de>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
