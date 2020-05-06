use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'HTML::Selector::Element',
    VERSION_FROM    => 'lib/HTML/Selector/Element.pm',
    ABSTRACT_FROM   => 'lib/HTML/Selector/Element.pod',
    MIN_PERL_VERSION => '5.008001',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    'PREREQ_PM'    => { 'strict'      => 0,
                        'Exporter'    => 0,
                        'Carp'        => 0,
                        'HTML::TreeBuilder' => 0,
    }, # e.g., Module::Name => 1.1
    AUTHOR         => 'Bart Lateur <bartl@cpan.org>',
    LICENSE        => 'perl'
);
