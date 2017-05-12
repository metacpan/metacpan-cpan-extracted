use strict;
use warnings;
require 5.008001;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => 0.28,
    },
    module_name        => 'HTML::Template::Compiled::Plugin::DHTML',
    dist_author        => 'Tina Mueller',
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.28,
    },
    requires => {
        'perl'                      => '5.8.1',
        'Data::TreeDumper'          => 0,
        'Data::TreeDumper::Renderer::DHTML' => 0,
        'HTML::Template::Compiled'  => 1,
    },
    create_readme      => 1,
    sign               => 0,
    meta_merge => {
        resources => {
            repository  => 'https://github.com/perlpunk/HTML-Template-Compiled-Plugin-DHTML',
        },
    },
);
$build->create_build_script;

