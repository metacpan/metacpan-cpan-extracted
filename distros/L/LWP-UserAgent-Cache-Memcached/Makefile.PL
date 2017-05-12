use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'LWP::UserAgent::Cache::Memcached',
    VERSION_FROM      => 'lib/LWP/UserAgent/Cache/Memcached.pm',
    PREREQ_PM         => {
        'Test::More'  => '0',
        'LWP::UserAgent' => 0,
        'Cache::Memcached' => '0',
        'Module::Load' => '0',
    },
);

