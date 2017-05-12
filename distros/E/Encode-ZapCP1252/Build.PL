use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Encode::ZapCP1252',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    requires           => { 'perl'          => 5.006_002  },
    configure_requires => { 'Module::Build' => '0.36' },
    recommends         => {
        'Test::Pod' => '1.41',
        'Encode'    => 0,
    },
    build_requires     => {
        'Test::More'    => '0.17',
        'Module::Build' => '0.36',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Encode-CP1252/',
            bugtracker => 'http://github.com/theory/encode-cp1252/issues/',
            repository => 'http://github.com/theory/encode-cp1252/tree',
        }
    },
);
$build->create_build_script;
