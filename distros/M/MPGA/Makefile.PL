use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MPGA',
    VERSION_FROM      => 'lib/MPGA.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                   'Test::More' => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/MPGA.pm', # retrieve abstract from module
    AUTHOR            => 'NN<autumNN@yandex.ru>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
