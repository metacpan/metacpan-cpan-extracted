use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'LWP::UserAgent::WithCache',
    VERSION_FROM      => 'lib/LWP/UserAgent/WithCache.pm',
    PREREQ_PM         => {
        LWP::UserAgent => 0,
        Cache::FileCache => 0,
        File::HomeDir => 0,
    }, 
);
