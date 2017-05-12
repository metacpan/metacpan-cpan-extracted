use Module::Build;

Module::Build -> new
(
	module_name		=> 'Javascript::MD5',
	license			=> 'artistic',
	dist_author		=> 'Ron Savage <ron@savage.net.au>',
	build_requires	=>
	{
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	requires		=> {},
) -> create_build_script();
