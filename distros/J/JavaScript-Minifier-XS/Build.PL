use strict;
use warnings;
use Module::Build;

Module::Build->new(
    'module_name'       => 'JavaScript::Minifier::XS',
    'license'           => 'perl',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'create_makefile_pl'=> 'traditional',
    'xs_files'          => {
        'XS.xs' => 'lib/JavaScript/Minifier/XS.xs',
        },
    'requires'          => {
        'perl'                  => '5.6.0',
        },
    'build_requires'    => {
        'Test::More'            => 0,
        'ExtUtils::CBuilder'    => 0,
        },
    )->create_build_script();
