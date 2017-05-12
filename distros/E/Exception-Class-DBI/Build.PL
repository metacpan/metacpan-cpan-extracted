use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Exception::Class::DBI',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
        'Test::Harness' => '2.03',
    },
    requires           => {
        'DBI'              => '1.28',
        'Exception::Class' => '1.02',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Exception-Class-DBI/',
            bugtracker => 'http://github.com/theory/exception-class-dbi/issues/',
            repository => 'http://github.com/theory/exception-class-dbi/',
        }
    },
);
$build->create_build_script;
