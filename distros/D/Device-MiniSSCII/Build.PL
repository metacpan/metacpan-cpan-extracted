use Module::Build;
my $bld = Module::Build->new(
	module_name => 'Device::MiniSSCII',
	dist_name => 'Device-MiniSSCII',
	license => 'perl',
	script_files => [ 'bin/minisscii' ],
	requires => {
		Device::SerialPort => 0
		},
	create_makefile_pl => 'passthrough'
	);
$bld->create_build_script;
