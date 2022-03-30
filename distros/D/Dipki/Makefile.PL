use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Dipki',
    VERSION_FROM      => 'lib/Dipki.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'strict' => 0,
        'warnings' => 0,
        'Win32::API' => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Dipki.pm', # retrieve abstract from module
    AUTHOR            => 'David Ireland, <https://www.cryptosys.net/contact/>',
    LICENSE           => 'mit',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
