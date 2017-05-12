use ExtUtils::MakeMaker;
use 5.006;

WriteMakefile(
    NAME         => 'Math::BigInt::Random',
    VERSION_FROM => 'lib/Math/BigInt/Random.pm', # finds $VERSION
    AUTHOR       => 'William Hererra (whererra@skylightview.com)',
    ABSTRACT     => 'Create random very large integers',
    PREREQ_PM    => { Math::BigInt => 0, Carp => 0, Test::More => 0 },
    LICENSE      => 'perl',
);
