use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => "JSV::Compiler",
    AUTHOR           => "Anton Petrusevich",
    VERSION          => "0.07",
    INSTALLDIRS      => 'site',
    LICENSE          => "artistic_2",
    MIN_PERL_VERSION => "5.008000",
    META_MERGE       => {
        "meta-spec" => {version => 2},
        resources   => {
            bugtracker => {web => 'https://github.com/jef-sure/jsv-compilator/issues'},
            repository => {
                type => 'git',
                url  => 'https://github.com/jef-sure/jsv-compilator.git',
                web  => 'https://github.com/jef-sure/jsv-compilator',
            },
        },
    },
    PREREQ_PM => {
        'JSON'                           => 0,
        'YAML::XS'                       => 0,
        'JSON::Pointer'                  => 0,
        'Path::Tiny'                     => 0,
        'Storable'                       => 0,
        'Data::Dumper'                   => 0,
        'List::Util'                     => '1.33',
        'Regexp::Common'                 => 0,
        'Regexp::Common::time'           => 0,
        'Regexp::Common::Email::Address' => 0,
        'Regexp::Common::URI'            => 0,
    },
    BUILD_REQUIRES => {'ExtUtils::MakeMaker' => "6.64",},
    TEST_REQUIRES  => {
        'Test::Most' => 0,
        'JSON'       => "2.91",
    },
    test => {TESTS => "t/*.t"},
    dist => {
        DIST_DEFAULT => 'all tardist',
        COMPRESS     => 'gzip -vf',
        SUFFIX       => '.gz',
    },
    clean     => {FILES => '*~',},
    realclean => {FILES => '*~',},
);
