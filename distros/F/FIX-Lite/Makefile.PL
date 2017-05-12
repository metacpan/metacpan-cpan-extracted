use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'FIX::Lite',
    VERSION_FROM      => 'lib/FIX/Lite.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/FIX/Lite.pm', # retrieve abstract from module
    AUTHOR            => 'Vitaly Agapov <agapov.vitaly@gmail.com>',
    #LICENSE           => 'perl',
);
