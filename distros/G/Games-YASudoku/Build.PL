use Module::Build;

my $build_pkg = 'Module::Build';

my $build = $build_pkg->new(
            module_name => 'Games::YASudoku',
            license => 'perl',
            recursive_test_files => 1,
            requires => {
                         'perl'           => '5.8.6',
                        },
            add_to_cleanup => [ qw( t/logs MANIFEST.bak ) ],
            create_makefile_pl => 'passthrough',
           );

$build->create_build_script;

