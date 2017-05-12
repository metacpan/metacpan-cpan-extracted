use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Math::ODE',
    license             => 'perl',
    dist_author         => 'Jonathan "Duke" Leto <jonathan@leto.net>',
    dist_version_from   => 'lib/Math/ODE.pm',
    dist_abstract	    => 'Solve N-th Order Differential Equations',
    build_requires => {
        'Test::More'   => 0,
        'Data::Dumper' => 0,
        'Carp'	       => 0,
    },
    add_to_cleanup      => [ 'Math::ODE-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/leto/math--ode/tree/master'
        },
    },
);

$builder->create_build_script();
print "Have a great day!\n";
