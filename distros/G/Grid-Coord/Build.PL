use Module::Build;
      my $build = Module::Build->new
        (
         module_name => 'Grid::Coord',
         license => 'perl',
         requires => {
                      'perl'           => '5.6.1',
                     },
         build_requires => {
            'Module::Build' => 0,
            'Test::More' => 0,
            },
         create_readme => 1,   
        );
      $build->create_build_script;

