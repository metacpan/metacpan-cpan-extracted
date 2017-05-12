use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'HTML::Template::Filter::URIdecode',
      license         => 'perl',
      requires        => {
          URI::Escape => 0,
      }
    )->create_build_script;
