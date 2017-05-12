use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MasonX::StaticBuilder',
    license             => 'perl',
    dist_author         => 'Kirrily Robert <skud@cpan.org>',
    dist_version_from   => 'lib/MasonX/StaticBuilder.pm',
    build_requires => {
        'Test::More' => 0,
        'File::Find::Rule' => 0,
    },
    add_to_cleanup      => [ 'MasonX-StaticBuilder-*' ],
);

$builder->create_build_script();
