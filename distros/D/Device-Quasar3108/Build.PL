use Module::Build;

my $build = Module::Build->new
(
	module_name => 'Device::Quasar3108',
	license => 'perl',
	build_requires => {
		'Module::Build' => '0.20'
	},
	
	create_makefile_pl => 'passthrough',
	
	requires => {
		'perl'	=> '5.5.0',
		'Test' => '1.00',
		'Time::HiRes' => 0,
		'Device::SerialPort' => '0.20',
	}
);

$build->create_build_script;
