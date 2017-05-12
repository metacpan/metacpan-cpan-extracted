use Module::Build;

Module::Build->new(
    module_name => 'Math::StochasticProcess',
    license => 'perl',
    requires => {
        'Params::Validate' => 0,
	'Exporter'=>'5.57',
    },
    build_requires => {
        'Test::More' => 0,
        'File::Spec' => 0, # needed for test log files
    },
    meta_merge => {
        resources=> {
            repository => 'http://github.com/periapt/math-stochasticprocess.git',
        },
        keywords => ['math','probability','stochastic process'],
    },
    create_makefile_pl => 'traditional',
    dist_author => 'Nicholas Bamber <nicholas@periapt.co.uk>',
)->create_build_script;

