use Module::Build;

my $build = Module::Build->new(
    module_name        => 'FSA::Rules',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    requires           => {
        perl         => 5.006_002,
        Scalar::Util => '1.01',
    },
    configure_requires => { 'Module::Build' => '0.42'  },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    recommends         => {
        'GraphViz'       => '2.00',
        'Text::Wrap'     => 0,
        'Storable'       => '2.05',
        'B::Deparse'     => '0.61',
        'Test::Pod'      => '1.41',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/FSA-Rules/',
            bugtracker => 'http://github.com/theory/fsa-rules/issues/',
            repository => 'http://github.com/theory/fsa-rules/',
        }
    },
);
$build->create_build_script;
