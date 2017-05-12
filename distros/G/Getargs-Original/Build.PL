use Module::Build;

my $build = Module::Build->new(
	module_name  => 'Getargs::Original',
	license      => 'perl',
	dist_version => 0.1,
    requires     => {
        'Class::MethodMaker' => '1.12',
    },
);

$build->create_build_script;
