use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::FromArrayref',
    license             => 'perl',
    dist_author         => q{Nic Wolff <nic@angel.net>},
    dist_version_from   => 'lib/HTML/FromArrayref.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
	'HTML::Entities' => 0,
    },
    add_to_cleanup      => [ 'HTML-FromArrayref-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
