use Module::Build;

my $b = Module::Build->new(
    'module_name'        => 'MARC::Xform',
    'dist_abstract'      => 'MARC record transformations',
    'script_files'       => [ ],
    'license'            => 'perl',
    'requires'           => {
        'MARC::Loop'          => 0,
    },
    'build_requires'     => {
        'Test::More'         => 0,
    },
    'create_makefile_pl' => 'traditional',
    'create_readme'      => 0,
    'sign'               => 0,
);

$b->create_build_script;

