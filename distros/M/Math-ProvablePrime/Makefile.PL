use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Math::ProvablePrime',
    VERSION_FROM => 'lib/Math/ProvablePrime.pm',    # finds \$VERSION
    ABSTRACT_FROM => 'lib/Math/ProvablePrime.pm',    # finds \$VERSION
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
        'Math::BigInt' => 1.999806,
        'Bytes::Random::Secure::Tiny' => 1.008,
    },
    TEST_REQUIRES => {
        'Test::Class' => 0.4,
        'Test::NoWarnings' => 0.01,
        'Test::Deep' => 0,
        'Test::More' => 0.01,
        'Test::Exception' => 0,
        'Test::NoWarnings' => 0,
        'File::Which' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Math-ProvablePrime.git',
                web  => 'https://github.com/FGasper/p5-Math-ProvablePrime',
            },
        },
    },
);
