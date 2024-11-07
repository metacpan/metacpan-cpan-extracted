use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MFab::Plugins::Datadog',
    VERSION_FROM      => 'lib/MFab/Plugins/Datadog.pm',
    PREREQ_PM         => {
        'Test::More' => 0,
        'Mojo::Base' => 0,
        'Time::HiRes' => 0,
        'Crypt::Random' => 0,
        'Math::Pari' => 0,
    },
    ABSTRACT_FROM     => 'lib/MFab/Plugins/Datadog.pm',
    AUTHOR            => 'Daniel Drown',
    LICENSE           => 'perl',
    MIN_PERL_VERSION  => '5.010',
);
