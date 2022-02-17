use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Genealogy::AncestorChart',
    VERSION_FROM      => 'lib/Genealogy/AncestorChart.pm',
    PREREQ_PM         => {
        Moo                  => 0,
        Types::Standard      => 0,
    },
    BUILD_REQUIRES    => {
        Test::More    => 0,
    },
    ABSTRACT_FROM     => 'lib/Genealogy/AncestorChart.pm',
    AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION  => '5.6.0',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/davorg/genealogy-ancestorchart.git',
                web => 'https://github.com/davorg/genealogy-ancestorchart',
            },
            bugtracker => {
                web => 'https://github.com/davorg/genealogy-ancestorchart/issues',
            },
        },
    },
);
