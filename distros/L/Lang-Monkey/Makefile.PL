use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lang::Monkey',
    VERSION_FROM      => 'lib/Lang/Monkey.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Lang/Monkey.pm', # retrieve abstract from module
    AUTHOR            => 'Rajkumar Reddy',
    EXE_FILES         => ['script/mpl'],
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
