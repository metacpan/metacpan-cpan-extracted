use Module::Build;
my $build = Module::Build->new(
        module_name => 'Geo::Coordinates::RDNAP',
        license     => 'perl',
        requires    => {
                         'Params::Validate' => '0',
                       },
        build_requires => { 'Test::More' => 0.34, },
        recommends  => { 'Test::Pod' => 1, },
        create_makefile_pl => 'passthrough',
        dist_author => 'Eugene van der Pijll',
        dist_abstract => 'Convert coordinates from/to the Dutch RD-NAP system',
);
$build->create_build_script;
