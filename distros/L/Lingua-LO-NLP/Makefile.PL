use ExtUtils::MakeMaker;

BEGIN {
    eval { require ExtUtils::MakeMaker::Coverage; };
    ExtUtils::MakeMaker::Coverage->import unless $@;
}

WriteMakefile(
    NAME         => 'Lingua::LO::NLP',
    VERSION_FROM => 'lib/Lingua/LO/NLP.pm',
    AUTHOR       => 'Matthias Bethke <mbethke@cpan.org>',
    ABSTRACT     => 'Various language processing functions for Lao text',
    MIN_PERL_VERSION => '5.012000',
    PREREQ_PM    => {
        version => 0.77,
        Carp    => 0,
        charnames => 0,
        'Unicode::Normalize' => 0,
        'Class::Accessor::Fast' => 0,
        'List::Util' => 1.33,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Fatal' => 0,
    },
    dist => {
        COMPRESS        => 'bzip2',
        SUFFIX          => '.bz2',
    },
    LICENSE           => 'perl',
);
