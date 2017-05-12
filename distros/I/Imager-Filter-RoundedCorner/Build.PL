use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'Imager::Filter::RoundedCorner',
    license     => 'perl',
    requires    => {
        Imager => '0.50',
    },
)->create_build_script;
