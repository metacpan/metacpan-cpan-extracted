use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'File::System',
	create_makefile_pl => 'passthrough',
	license            => 'perl',
	requires           => {
		'File::Copy::Recursive' => '0.05',
		'Parse::RecDescent'     => 1.94,
	},
	PL_files			=> {
		'lib/File/System/Globber.PL' => 'lib/File/System/Globber.pm',
	},
);

$build->create_build_script;
