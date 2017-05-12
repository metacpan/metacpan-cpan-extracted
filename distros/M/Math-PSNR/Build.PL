use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name              => 'Math-PSNR',
    module_name       => 'Math::PSNR',
    license           => 'perl',
    dist_author       => 'moznion <moznion@gmail.com>',
    dist_version_from => 'lib/Math/PSNR.pm',
    dynamic_config    => 0,
    build_requires    => {
        'Test::More'      => '0.98',
        'Test::Exception' => '0.31',
        'Test::Warn'      => '0.24',
    },
    configure_requires => { 'Module::Build' => '0.40' },
    requires           => {
        perl     => '5.008001',
        'parent' => 0,
        'Carp'   => 0,
        'Mouse'  => '1.02',
    },
    no_index   => { 'directory' => ['inc'] },
    meta_merge => {
        'resources' => {
            'license'    => 'http://dev.perl.org/licenses/',
            'repository' => 'git://github.com/moznion/p5-Math--PSNR.git'
        },
    },
    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
    add_to_cleanup       => ['Math-PSNR-*'],
    create_readme        => 1,
    create_license       => 1,
);

$builder->create_build_script();
