use strict;
use Module::Build;
use File::Spec;
my $script = File::Spec->catfile( 'script',
		Module::Build->os_type eq 'Windows'  
			? 'file-rename' : 'rename' );

Module::Build -> new (
	license		=> 'perl',	
	script_files	=> [ $script ],
	module_name	=> 'File::Rename',
	PL_files	=> { 'rename.PL' => $script },
	#   create_makefile_pl	=> 'traditional'
	requires	=> {
		'Getopt::Long'	=> 0,
		perl 		=> 5,
	},
	configure_requires => { 'Module::Build' => 0.40 },
	build_requires	=> {
		'File::Temp'	=> 0,
		'Test::More'	=> 0,
	},
	configure_requires => { 'Module::Build' => 0.38 },
	recommends	=> {
		'Getopt::Long'	=> 2.24, # for Configure qw(posix_default);
		'Test::Pod' 	=> 0,
		'File::Spec'	=> 0.82, # required for Pod::Parser, for ...
		'Test::Pod::Coverage' => 0,
	}
) -> create_build_script;

