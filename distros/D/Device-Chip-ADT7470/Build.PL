use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Device::Chip::ADT7470',
    requires    => {
        'Data::Bitfield'                    => 0,
        'Device::Chip'                      => '0.04',
	'Device::Chip::Base::RegisteredI2C' => '0.10',
	'Carp'                              => 0,
    },
    build_requires => {
        'Test::Device::Chip::Adapter' => 0,
        'Test::More'                  => '0.88',    # done_testing
        'Test::Exception'             => '0.43',
    },
    meta_merge => {
	resources => {
	    repository => 'https://github.com/john-/Device-Chip-ADT7470'
	}
    },
    auto_configure_requires => 0,         # Don't add M::B to configure_requires
    license                 => 'perl',
    create_makefile_pl      => 'traditional',
    create_license          => 1,
    create_readme           => 1,
    dist_author             => 'the author',
);

$build->create_build_script;
