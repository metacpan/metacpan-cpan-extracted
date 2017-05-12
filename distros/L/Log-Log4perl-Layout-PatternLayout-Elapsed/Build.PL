use Module::Build;

my $build = Module::Build->new(
	module_name => 'Log::Log4perl::Layout::PatternLayout::Elapsed',
	license  => 'perl',
	requires => {
		'Log::Log4perl::Layout::PatternLayout' => 0,
	},
	build_requires => {
		'Test::More'=> 0,
		'Log::Log4perl::Appender::TestBuffer' => 0,
	},
	recommends => {
		'Time::HiRes' => 0
	},
	
	dynamic_config => 0,
);

$build->create_build_script;
