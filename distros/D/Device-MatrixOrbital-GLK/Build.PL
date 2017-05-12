use Module::Build;

my $build = Module::Build->new
(
	module_name => 'Device::MatrixOrbital::GLK',
	license => 'perl',
	build_requires => {
		'Module::Build' => '0.20'
	},
	requires => {
		'perl'	=> '5.5.0',
		'Device::SerialPort' => 0,
		'Time::HiRes' => 0,
		'Test::More' => 0,
		'Test::Pod' => 0,
		'Params::Util' => 0,
	},
	
	create_makefile_pl => 'passthrough',
);

$build->create_build_script;
