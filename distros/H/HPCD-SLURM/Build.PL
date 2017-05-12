# Safe Perl
use strict;
use autodie;

use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'HPCD-SLURM',
	license             => 'perl',
	dist_author         => ['Anqi (Joyce) Yang  <ayang2@oicr.on.ca>'],

	dist_version_from   => 'lib/HPCD/SLURM.pm',
	dist_abstract       => 'A SLURM-specific driver for HPCI',

	# Modules required to use this module
	test_requires => {
		'Config'                     => '0',
		'File::Temp'                 => '0',
		'File::pushd'                => '0',
		'File::ShareDir'             => '0',
		'FindBin'                    => '0',
		'Test::Exception'            => '0',
			'Test::More'                 => '0.10',
		'MooseX::Types::Path::Class' => '0',
		},
	configure_requires => {
		'Module::Build'		     => 0.42
		},
	requires => {
		'HPCI'				=> '0.41',
		'Carp'				=> '0',
		'Data::Dumper'			=> '0',
		'DateTime'			=> '0',
		'Module::Load::Conditional'	=> '0',
		'Moose'				=> '0',
		'Moose::Role'			=> '0',
		'Moose::Util::TypeConstraints'	=> '0',
		'MooseX::ClassAttribute'	=> '0',
		'namespace::autoclean'		=> '0',
		},
	);

$builder->create_build_script();
