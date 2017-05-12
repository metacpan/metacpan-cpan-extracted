use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Method::Declarative',
      license         => 'perl',
      dist_author     => q(Jim Schneider <perl@jrcsdevelopment.com>),
      requires        =>
      {
                perl => '5.6.0',
                'Module::Build' => '0.28',
		'Test::More' => 0,
      },
    )->create_build_script;
