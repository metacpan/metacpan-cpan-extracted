use Module::Build;
my $build = Module::Build->new(
    module_name => 'GD::Graph::sparklines',
    license => 'perl',
    requires => {
        'GD::Graph' => 0,
        'Test::More' => 0
    },
    create_makefile_pl => 'passthrough'
);
$build->create_build_script;
