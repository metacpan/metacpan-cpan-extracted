use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'File::Find::Random',
      
      license         => 'perl',
      requires        => {
	  perl => '5.6.0',
	  Error => '0.15',
	  File::Find => '1.04',
      },
      build_requires => {
	  Test::Pod => 0,
	  Test::More => 0,
      },
      dynamic_config => 0,
      sign => 1,
    )->create_build_script;
