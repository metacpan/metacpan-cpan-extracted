use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Math::MatrixReal',
    license           => 'perl',
    dist_author       => 'Jonathan Leto <jonathan@leto.net>',
    dist_version_from => 'lib/Math/MatrixReal.pm',
    dist_abstract     => 'Manipulate NxN matrices of real numbers',
    license           => 'perl',
    build_requires => {
        'Test::Most' => 0,
        'File::Spec' => 0,
    },
    configure_requires => { 'Module::Build' => 0.38 },
    add_to_cleanup      => [ 'Math::MatrixReal-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/leto/math--matrixreal/tree/master'
        },
    },
);

$builder->create_build_script();
print "Have an awesome day!\n";
