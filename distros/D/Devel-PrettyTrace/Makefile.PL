use ExtUtils::MakeMaker;

system 'pod2text lib/Devel/PrettyTrace.pod > README';

WriteMakefile(
    NAME            => 'Devel::PrettyTrace',
    VERSION_FROM    => 'lib/Devel/PrettyTrace.pm',
    AUTHOR          => ['Sergey Aleynikov <randir@cpan.org>'],
    TEST_REQUIRES   => {
        'Test::More'        => 0,
    },
    PREREQ_PM       => {
        'Data::Printer'     => '0.19',
        'Exporter'          => 0,
        'parent'            => 0,
        'List::Util'        => '1.43',
    },
    META_MERGE      => {
        resources     => {
            repository  => 'https://github.com/dur-randir/Devel-PrettyTrace',
            bugtracker  => 'https://github.com/dur-randir/Devel-PrettyTrace/issues',
        },
        dynamic_config  => 0,
    },
    ABSTRACT_FROM   => 'lib/Devel/PrettyTrace.pod',
    LICENSE         => 'perl',
    MIN_PERL_VERSION=> 5.006,
);
