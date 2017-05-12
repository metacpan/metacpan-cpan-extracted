use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'List::Extract',
    VERSION_FROM => 'lib/List/Extract.pm',
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'List::Extract',
    PREREQ_PM    => {
        Test::More => 0.45,
    },
);
