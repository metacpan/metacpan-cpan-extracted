
use Module::Build;
Module::Build->new(
	module_name    => 'Gopher::Server', 
	dist_version   => 0.1.1, 
	dist_author    => 'Timm Murray <tmurray@cpan.org>', 
	dist_abstract  => 'Backend for Gopher Servers', 
	license        => 'gpl', 
	requires       => {
		perl           => '5.6.0', 
		'Net::Gopher'  => '0.96', 
	}, 
	build_requires  => {
		'IO::Scalar'        => 0, 
		'Test::Exception'   => 0, 
	}, 
	create_makefile_pl  => 'passthrough', 
)->create_build_script;

