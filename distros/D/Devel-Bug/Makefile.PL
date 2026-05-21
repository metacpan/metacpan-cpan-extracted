use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Devel::Bug',
    AUTHOR           => 'Kevin Shea <KEVJSHEA@cpan.org>',
    VERSION_FROM     => 'lib/Devel/Bug.pm',
    ABSTRACT_FROM    => 'lib/Devel/Bug.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.020',

    PREREQ_PM => {
        'Carp'            => 0,
        'Data::Dumper'    => 0,
        'Term::ANSIColor' => 0,
    },

    TEST_REQUIRES => {
        'Test2::V0'        => 0,
        'Data::Dump'       => 0,
        'Term::Size::Perl' => 0,
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => { web  => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Bug' },
            repository => { url  => 'https://github.com/ASquareClock/Devel-Bug.git',
                            web  => 'https://github.com/ASquareClock/Devel-Bug',
                            type => 'git' },
        },
        provides => {
            'Devel::Bug' => {
                file    => 'lib/Devel/Bug.pm',
                version => '0.08',
            },
        },
        prereqs => {
            runtime => {
                suggests => {
                    'Data::Dump'       => 0,
                    'Term::Size::Perl' => 0,
                },
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', TAR => '/usr/local/bin/gtar', TARFLAGS => 'cvf' },
    clean => { FILES => 'Devel-Bug-*' },
);
