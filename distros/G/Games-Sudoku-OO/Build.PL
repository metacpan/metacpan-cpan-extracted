use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Games::Sudoku::OO::Board',
      dist_name       => 'Games-Sudoku-OO',
      license         => 'perl',
      script_files    => [('scripts/sudokusolve')],
      )->create_build_script;
