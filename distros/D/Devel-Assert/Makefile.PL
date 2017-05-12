use 5.014;
use ExtUtils::MakeMaker;

system 'pod2text lib/Devel/Assert.pod > README';

WriteMakefile(
    NAME            => 'Devel::Assert',
    VERSION_FROM    => 'lib/Devel/Assert.pm',
    AUTHOR          => ['Sergey Aleynikov <randir@cpan.org>'],
    PREREQ_PM       => {
    },
    TEST_REQUIRES   => {
        'Test::More'        => 0,
        'Test::Exception'   => 0,
    },
    META_MERGE      => {
        resources     => {
            repository  => 'https://github.com/dur-randir/Devel-Assert',
        },
    },
    ABSTRACT_FROM   => 'lib/Devel/Assert.pod',
    LICENSE         => 'perl',
    MIN_PERL_VERSION=> 5.014,
);

