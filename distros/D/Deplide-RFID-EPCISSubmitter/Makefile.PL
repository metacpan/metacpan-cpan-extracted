use 5.032001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Deplide::RFID::EPCISSubmitter',
    VERSION_FROM      => 'lib/Deplide/RFID/EPCISSubmitter.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Deplide/RFID/EPCISSubmitter.pm', # retrieve abstract from module
    AUTHOR            => 'Eddie Olsson <eddie@>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
