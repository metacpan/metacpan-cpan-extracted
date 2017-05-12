use 5.006;
use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name    => 'JS::JSLint',
    create_readme  => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    requires => {
        'perl' => '5.6.0',
        'JS'   => 0,
    },
    meta_merge => {
        resources => {
            homepage   => 'https://github.com/patch/js-jslint-pm5',
            repository => 'https://github.com/patch/js-jslint-pm5.git',
            bugtracker => 'https://github.com/patch/js-jslint-pm5/issues',
        },
    },
);

$builder->add_build_element('js');
$builder->create_build_script;
