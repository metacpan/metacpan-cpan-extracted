use 5.020002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Device::PaPiRus',
    VERSION_FROM      => 'lib/Device/PaPiRus.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'GD' => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Device/PaPiRus.pm', # retrieve abstract from module
    AUTHOR            => 'Rene Schickbauer <rene.schickbauer@gmail.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
