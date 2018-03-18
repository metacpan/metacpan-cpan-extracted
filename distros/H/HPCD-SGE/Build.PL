# Safe Perl
use strict;
use autodie;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HPCD-SGE',
    license             => 'perl',
    dist_author         => ['John Macdonald  <jmacdonald@oicr.on.ca>'],

    dist_version_from   => 'lib/HPCD/SGE.pm',
    dist_abstract       => 'HPCI driver for SGE cluster interface.',

    # Modules required to use this module
    test_requires => {
		'Config'                       => '0',
		'File::Temp'                   => '0',
		'File::pushd'                  => '0',
		'File::ShareDir'               => '0',
		'FindBin'                      => '0',
        'Test::Exception'              => '0',
        'Test::More'                   => '0.10',
		'MooseX::Types::Path::Class'   => '0',
    },
    configure_requires => {
		'Module::Build'                => 0.42
	},
    requires => {
		'HPCI'                         => '0.40',
		'Carp'                         => '0',
		'Data::Dumper'                 => '0',
		'DateTime'                     => '0',
		'Module::Load::Conditional'    => '0',
		'Moose'                        => '0',
		'Moose::Role'                  => '0',
		'Moose::Util::TypeConstraints' => '0',
		'MooseX::ClassAttribute'       => '0',
		'namespace::autoclean'         => '0',
    },
	recommends => {
		'Schedule::DRMAAc'             => '0.81',
	},
);

$builder->create_build_script();
