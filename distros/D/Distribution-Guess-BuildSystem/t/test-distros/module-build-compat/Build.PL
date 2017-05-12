# In a Build.PL :
use Module::Build;

my $build = Module::Build->new
	( 
	module_name        => 'Foo::Bar',
	license            => 'perl',
	create_makefile_pl => 'passthrough' 
	);
