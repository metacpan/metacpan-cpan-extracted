use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'HTML::Prototype::Useful',
    requires           => {
     'HTML::Prototype' => 1.45
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files   => [
        glob('t/*.t') 
    ]
);
$build->create_build_script;
