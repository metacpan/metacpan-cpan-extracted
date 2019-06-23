use Module::Build;

my $build = Module::Build->new(
    module_name   => 'LCFG::Build::PkgSpec',
    dist_abstract => 'Object-oriented interface to LCFG build metadata',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '0.2.7',
    license => 'gpl',
    requires => {
        'perl'                      => '5.10.0',
        'Data::Structure::Util'     => '0.12',
        'DateTime'                  => '0',
        'Email::Address'            => '0',
        'Email::Valid'              => '0',
        'Moose'                     => '0.98',
        'Pod::Usage'                => '0',
        'YAML::Syck'                => '0.98',
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
    },
    add_to_cleanup => [ 'LCFG-Build-PkgSpec-*', 'MANIFEST.bak', 'Changes.bak' ],
    create_makefile_pl => 'traditional',
);
$build->create_build_script;
