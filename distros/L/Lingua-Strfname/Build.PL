use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Lingua::Strfname',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    requires           => { perl            => 5.006    },
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Lingua-Strfname/',
            bugtracker => 'http://github.com/theory/lingua-strfname/issues/',
            repository => 'http://github.com/theory/lingua-strfname/',
        }
    },
);
$build->create_build_script;
