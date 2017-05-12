use strict;
use Module::Build;

Module::Build->new(
    module_name     => 'EO',
    license         => 'perl',
    requires        => {
	'perl'                     => 5.008,
        'Attribute::Handlers'      => '0.01',
	'Class::Accessor::Chained' => 0,
        'Clone'                    => '0.01',
        'Data::Structure::Util'    => '0.06',
        'Data::UUID'               => '0.01',
        'Error'                    => '0.15',
        'Path::Class'              => '0.01',
        'Scalar::Util'             => '1.02',
    },
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
