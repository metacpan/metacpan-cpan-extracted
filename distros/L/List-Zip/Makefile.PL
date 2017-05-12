use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'List::Zip',
    VERSION_FROM => 'lib/List/Zip.pm',
    AUTHOR       => 'Lloyd Griffiths (lloydg@cpan.org)',
    ABSTRACT     => 'Module to zip lists',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Test::Simple' => 0.44,
    },
    META_MERGE   => {
        resources => {
            repository => 'https://github.com/LloydGriffiths/List-Zip',
        },
    },
);
