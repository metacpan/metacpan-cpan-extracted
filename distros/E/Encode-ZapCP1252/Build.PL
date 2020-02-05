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
            homepage   => 'https://search.cpan.org/dist/Encode-ZapCP1252/',
            bugtracker => 'https://github.com/theory/encode-zapcp1252/issues/',
            repository => 'https://github.com/theory/encode-zapcp1252',
        }
    },
);
$build->create_build_script;
