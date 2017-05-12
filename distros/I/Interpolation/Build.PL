use strict;
use warnings;
use Module::Build;

# require perl 5.8.1

my $builder = Module::Build->new(
    module_name         => 'Interpolation',
    license             => 'perl',
    dist_author         => 'Jan Krynicky (Jenda@Krynicky.cz), Mark-Jason Dominus (mjd@plover.com)',
    dist_version_from   => 'lib/Interpolation.pm',
	dist_abstract => "Arbitrary string interpolation semantics (using tie())",
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
    create_license  => 1,
);

$builder->create_build_script();
